SET search_path TO oceny_pracownikow;

CREATE VIEW v_dane_pracownikow AS
SELECT
    p.id_pracownika,
    p.imie,
    p.nazwisko,
    p.imie || ' ' || p.nazwisko AS imie_nazwisko,
    p.orcid,
    p.data_zatrudnienia,
    
    -- Dane o jednostce organizacyjnej (Katedra i Wydział)
    katedra.id_jednostki AS id_katedry,
    katedra.nazwa_jednostki AS nazwa_katedry,
    wydzial.id_jednostki AS id_wydzialu,
    wydzial.nazwa_jednostki AS nazwa_wydzialu,
    
    -- Dane o stanowisku
    ts.id_typu_stanowiska,
    ts.nazwa_typu AS nazwa_stanowiska,
    
    -- Dane o stopniu
    sn.id_stopnia,
    sn.nazwa_stopnia,
    
    -- Progi punktowe pobrane bezpośrednio dla tego pracownika
    ts.prog_punktowy_pub,
    ts.prog_punktowy_inny,
    ts.prog_punktowy_total
FROM
    oceny_pracownikow.pracownicy p
-- Łączenie z Katedrą (jednostka pracownika)
LEFT JOIN
    oceny_pracownikow.jednostki_organizacyjne katedra ON p.id_jednostki = katedra.id_jednostki
-- Łączenie Katedry z jej Wydziałem (jednostka nadrzędna katedry)
LEFT JOIN
    oceny_pracownikow.jednostki_organizacyjne wydzial ON katedra.id_jednostki_nadrzednej = wydzial.id_jednostki
-- Łączenie ze stanowiskiem
LEFT JOIN
    oceny_pracownikow.typy_stanowisk ts ON p.id_typu_stanowiska = ts.id_typu_stanowiska
-- Łączenie ze stopniem naukowym
LEFT JOIN
    oceny_pracownikow.stopnie_naukowe sn ON p.id_stopnia = sn.id_stopnia;

CREATE VIEW oceny_pracownikow.v_aktywnosci_szczegolowo AS
SELECT
    -- Dane z tabeli faktów (co pracownik zrobił)
    ap.id_aktywnosci,
    ap.id_pracownika,
    
    -- NOWE KOLUMNY DAT
    ap.data_rozpoczecia,
    ap.data_zakonczenia,
    
    ap.przyznane_punkty,
    ap.opis_szczegolowy,
    
    -- Dane ze słownika (czym jest ta aktywność)
    sta.id_typu_aktywnosci,
    sta.lp,
    sta.nazwa_parametru,
    sta.punkty_domyslne,
    sta.punkty_min,
    sta.punkty_max,
    
    -- NOWA KOLUMNA (Flaga logiczna dla formularza)
    sta.czy_ciagla,
    
    -- Dane z grupy (do jakiej kategorii należy)
    sgd.id_grupy,
    sgd.nazwa_grupy,
    sgd.kod_grupy -- 'PUB', 'BR', 'DYD', 'ORG'
FROM
    aktywnosci_pracownika ap
-- Łączenie z definicją aktywności
JOIN
    sl_typy_aktywnosci sta ON ap.id_typu_aktywnosci = sta.id_typu_aktywnosci
-- Łączenie z grupą nadrzędną
JOIN
    sl_grupy_dzialan sgd ON sta.id_grupy = sgd.id_grupy;

CREATE VIEW v_podsumowanie_punktow AS
-- Używamy CTE (Common Table Expressions) dla czytelności
WITH 
-- 1. Obliczamy faktyczne sumy punktów dla tych, co je mają
suma_aktywnosci AS (
    SELECT
        id_pracownika,
        kod_grupy,
        SUM(przyznane_punkty) AS suma_punktow
    FROM
        oceny_pracownikow.v_aktywnosci_szczegolowo
    GROUP BY
        id_pracownika, kod_grupy
),
-- 2. Tworzymy siatkę "każdy pracownik x każda kategoria"
pelna_siatka AS (
    SELECT
        p.id_pracownika,
        sgd.id_grupy,
        sgd.kod_grupy,
        sgd.nazwa_grupy
    FROM
        oceny_pracownikow.pracownicy p
    CROSS JOIN
        oceny_pracownikow.sl_grupy_dzialan sgd
)
-- 3. Łączymy siatkę z sumami; jeśli suma nie istnieje, wstawiamy 0
SELECT
    ps.id_pracownika,
    ps.id_grupy,
    ps.kod_grupy,
    ps.nazwa_grupy,
    -- Kluczowa funkcja: zamienia NULL (brak aktywności) na 0
    COALESCE(sa.suma_punktow, 0) AS suma_punktow
FROM
    pelna_siatka ps
LEFT JOIN
    suma_aktywnosci sa ON ps.id_pracownika = sa.id_pracownika 
                      AND ps.kod_grupy = sa.kod_grupy;

CREATE OR REPLACE VIEW v_dashboard_podsumowanie_live AS
WITH parametry AS (
    -- Pobieramy ustawienia z naszego filtra (zawsze 1 rekord)
    SELECT id_wybranego_pracownika, data_od, data_do FROM filtr_globalny WHERE id_filtra = 1
),
sumy AS (
    SELECT 
        sta.id_grupy,
        SUM(ap.przyznane_punkty) as suma
    FROM aktywnosci_pracownika ap
    JOIN sl_typy_aktywnosci sta ON ap.id_typu_aktywnosci = sta.id_typu_aktywnosci
    CROSS JOIN parametry p
    WHERE 
        ap.id_pracownika = p.id_wybranego_pracownika
        AND ap.data_rozpoczecia >= p.data_od 
        AND ap.data_rozpoczecia <= p.data_do
    GROUP BY sta.id_grupy
)
SELECT 
    sgd.nazwa_grupy,
    sgd.kod_grupy,
    COALESCE(s.suma, 0) as suma_punktow
FROM sl_grupy_dzialan sgd
LEFT JOIN sumy s ON sgd.id_grupy = s.id_grupy;

CREATE OR REPLACE VIEW v_raport_1_agregacja AS
SELECT
    -- Wyciągamy sam numer (np. '14' z '14a.') używając wyrażenia regularnego
    CAST(SUBSTRING(sta.lp FROM '^[0-9]+') AS INTEGER) as numer_lp,
    
    -- Sumujemy punkty dla tego numeru
    SUM(ap.przyznane_punkty) as suma_punktow
    
FROM 
    aktywnosci_pracownika ap
    JOIN sl_typy_aktywnosci sta ON ap.id_typu_aktywnosci = sta.id_typu_aktywnosci
    JOIN filtr_globalny f ON ap.id_pracownika = f.id_wybranego_pracownika
WHERE 
    -- Filtrowanie po dacie z Dashboardu
    ap.data_rozpoczecia >= f.data_od 
    AND ap.data_rozpoczecia <= f.data_do
GROUP BY 
    numer_lp;
