CREATE SCHEMA pcz_oceny;

SET search_path TO pcz_oceny;

-- Aktywności i okresy oceny
CREATE TABLE grupy_dzialan (
    id_grupy SERIAL PRIMARY KEY,
    nazwa_grupy VARCHAR(100) NOT NULL,
    kod_grupy VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE okresy_oceny (
	id_okresu SERIAL PRIMARY KEY,
	nazwa_okresu VARCHAR(200) NOT NULL,
	data_od DATE NOT NULL,
    data_do DATE NOT NULL,
	czy_aktywny BOOLEAN DEFAULT TRUE NOT NULL,
	
	CONSTRAINT chk_logika_dat CHECK (data_do >= data_od)
);

CREATE TABLE typy_aktywnosci (
	id_typu SERIAL PRIMARY KEY,
    nazwa_aktywnosci TEXT NOT NULL,
    id_grupy INT REFERENCES grupy_dzialan(id_grupy),
	czy_ciagla BOOLEAN DEFAULT FALSE NOT NULL,
	czy_udzial BOOLEAN DEFAULT FALSE NOT NULL
);

CREATE TABLE konfiguracja_aktywnosci (
    id_konfiguracja SERIAL PRIMARY KEY,
    id_okresu INT NOT NULL REFERENCES okresy_oceny(id_okresu),
    id_typu INT NOT NULL REFERENCES typy_aktywnosci(id_typu),
    punkty_domyslne NUMERIC(5,2),
    punkty_min NUMERIC(5,2),
    punkty_max NUMERIC(5,2),
    lp VARCHAR(10),
    kolejnosc INT NOT NULL DEFAULT 0,

    CONSTRAINT uq_okres_aktywnosc UNIQUE (id_okresu, id_typu)
);

--organizacja uczelni
CREATE TABLE jednostki_organizacyjne (
    id_jednostki SERIAL PRIMARY KEY,
    nazwa_jednostki VARCHAR(255) NOT NULL,
    id_jednostki_nadrzednej INT REFERENCES jednostki_organizacyjne(id_jednostki)
);

CREATE TABLE stopnie_tytuly (
    id_stopnia SERIAL PRIMARY KEY,
    nazwa_stopnia VARCHAR(60) NOT NULL,
	skrot VARCHAR(25) NOT NULL
);

CREATE TABLE grupy_stanowisk (
    id_grupy_stanowisk SERIAL PRIMARY KEY,
    nazwa_grupy VARCHAR(100) NOT NULL
);

CREATE TABLE stanowiska (
    id_stanowiska SERIAL PRIMARY KEY,
    nazwa_stanowiska VARCHAR(100) NOT NULL
);

CREATE TABLE konfiguracja_progi_punktowe (
	id_progu SERIAL PRIMARY KEY,
    id_okresu INT NOT NULL REFERENCES okresy_oceny(id_okresu),
    id_stanowiska INT NOT NULL REFERENCES stanowiska(id_stanowiska),
    id_grupy_stanowisk INT NOT NULL REFERENCES grupy_stanowisk(id_grupy_stanowisk),
	prog_punktowy_pub NUMERIC(6, 2) DEFAULT 0,
    prog_punktowy_dyd NUMERIC(6, 2) DEFAULT 0,
    prog_punktowy_org NUMERIC(6, 2) DEFAULT 0,
    prog_punktowy_total NUMERIC(6, 2) NOT NULL,
    
    CONSTRAINT uq_okres_stanowisko UNIQUE (id_okresu, id_stanowiska, id_grupy_stanowisk)
);

CREATE TABLE wymiar_etatu (
    id_etatu SERIAL PRIMARY KEY,
    opis_etatu VARCHAR(20) NOT NULL,
    wartosc_liczbowa NUMERIC(4, 3) NOT NULL,
	kolejnosc INT DEFAULT 0
);

CREATE TABLE pracownicy (
    id_pracownika SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    orcid VARCHAR(19),
    data_zatrudnienia DATE NOT NULL,
    czy_aktywny BOOLEAN DEFAULT TRUE NOT NULL,
    id_jednostki INT REFERENCES jednostki_organizacyjne(id_jednostki), 
	id_stopnia INT REFERENCES stopnie_tytuly(id_stopnia),
	id_stanowiska INT NOT NULL REFERENCES stanowiska(id_stanowiska),
	id_grupy_stanowisk INT NOT NULL REFERENCES grupy_stanowisk(id_grupy_stanowisk),
	id_etatu INT REFERENCES wymiar_etatu(id_etatu)
);

CREATE TABLE dziedziny (
    id_dziedziny SERIAL PRIMARY KEY,
    nazwa_dziedziny VARCHAR(255) NOT NULL
);

CREATE TABLE dyscypliny (
    id_dyscypliny SERIAL PRIMARY KEY,
    id_dziedziny INT NOT NULL REFERENCES dziedziny(id_dziedziny),
    nazwa_dyscypliny VARCHAR(255) NOT NULL
);

CREATE TABLE deklaracje (
    id_deklaracji SERIAL PRIMARY KEY,
    id_pracownika INT NOT NULL REFERENCES pracownicy(id_pracownika),
    id_okresu INT NOT NULL REFERENCES okresy_oceny(id_okresu), -- KLUCZOWA ZMIANA
    id_dyscypliny INT NOT NULL REFERENCES dyscypliny(id_dyscypliny),
    udzial_procentowy NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    czy_wiodaca BOOLEAN DEFAULT FALSE NOT NULL,
    
	CONSTRAINT chk_udzial_procentowy CHECK (udzial_procentowy > 0 AND udzial_procentowy <= 100),
    CONSTRAINT uq_deklaracja_w_okresie UNIQUE (id_pracownika, id_okresu, id_dyscypliny)
);

CREATE TABLE aktywnosci_pracownika (
    id_aktywnosci SERIAL PRIMARY KEY,
    id_pracownika INT NOT NULL REFERENCES pracownicy(id_pracownika),
    id_typu_aktywnosci INT NOT NULL REFERENCES typy_aktywnosci(id_typu), 
    data_rozpoczecia DATE NOT NULL,
    data_zakonczenia DATE, 
    udzial_procentowy NUMERIC(5, 2) DEFAULT 100.00 NOT NULL,
    przyznane_punkty NUMERIC(6, 2) NOT NULL,
    opis_szczegolowy TEXT,
    
    CONSTRAINT chk_logika_dat CHECK (data_zakonczenia IS NULL OR data_zakonczenia >= data_rozpoczecia),
    CONSTRAINT chk_udzial CHECK (udzial_procentowy > 0 AND udzial_procentowy <= 100)
);

CREATE TABLE oceny_okresowe (
    id_oceny SERIAL PRIMARY KEY,
    id_pracownika INT NOT NULL REFERENCES pracownicy(id_pracownika),
    id_okresu INT NOT NULL REFERENCES okresy_oceny(id_okresu),
    
    data_wyliczenia DATE DEFAULT CURRENT_DATE,
    
    -- Dane archiwalne pracownika
    arch_stopien VARCHAR(50),
    arch_stanowisko VARCHAR(100),
    arch_jednostka VARCHAR(255),
    arch_wymiar_etatu VARCHAR(50),
    arch_grupa_stanowisk VARCHAR(100),
    
    -- Punkty (bez NOT NULL, z domyślnym 0.00)
    suma_pkt_pub NUMERIC(7, 2) DEFAULT 0.00,
    suma_pkt_br NUMERIC(7, 2) DEFAULT 0.00,
    suma_pkt_dyd NUMERIC(7, 2) DEFAULT 0.00,
    suma_pkt_org NUMERIC(7, 2) DEFAULT 0.00,
    suma_pkt_total NUMERIC(7, 2) DEFAULT 0.00,
    
    -- ==========================================
    -- A. ETAP KIEROWNIKA / PRODZIEKANA
    -- ==========================================
    kier_data_oceny DATE DEFAULT CURRENT_DATE,
    kier_uzasadnienie_punktow TEXT,
    kier_uzasadnienie_oceny TEXT,
    kier_id_roli INT REFERENCES role_oceniajacych(id_roli),
    kier_id_oceny_pub INT REFERENCES skala_ocen(id_oceny),
    kier_id_oceny_br  INT REFERENCES skala_ocen(id_oceny),
    kier_id_oceny_dyd INT REFERENCES skala_ocen(id_oceny),
    kier_id_oceny_org INT REFERENCES skala_ocen(id_oceny),
    kier_id_oceny_total INT REFERENCES skala_ocen(id_oceny),
    -- Audyt
    kier_zatwierdzil_user VARCHAR(100),
    kier_zatwierdzil_data TIMESTAMP,

    -- ==========================================
    -- B. ETAP KOMISJI UCZELNIANEJ
    -- ==========================================
    kom_data_oceny DATE,
    kom_uzasadnienie TEXT,
    kom_wniosek_zatrudnienie TEXT,
    kom_id_oceny INT REFERENCES skala_ocen(id_oceny),
    -- Audyt
    kom_zatwierdzil_user VARCHAR(100),
    kom_zatwierdzil_data TIMESTAMP,

    -- ==========================================
    -- C. ETAP KOMISJI ODWOŁAWCZEJ
    -- ==========================================
    odw_czy_odwolanie BOOLEAN DEFAULT FALSE,
    odw_data_odwolania DATE,
    odw_data_decyzji DATE,
    odw_uzasadnienie TEXT,
    odw_id_decyzji INT REFERENCES decyzje_odwolawcze(id_decyzji),
    odw_id_oceny INT REFERENCES skala_ocen(id_oceny),
    -- Audyt
    odw_zatwierdzil_user VARCHAR(100),
    odw_zatwierdzil_data TIMESTAMP,

    CONSTRAINT uq_raport_okresowy UNIQUE (id_pracownika, id_okresu)
);

--PRZETESTOWAĆ
CREATE OR REPLACE VIEW v_aktualny_filtr AS
SELECT 
    ap.*,
    ta.nazwa_aktywnosci,
    p.imie,
    p.nazwisko
FROM 
    aktywnosci_pracownika ap
JOIN 
    filtr_uzytkownika f ON f.nazwa_uzytkownika = current_user
JOIN 
    typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu
JOIN 
    pracownicy p ON ap.id_pracownika = p.id_pracownika
WHERE 
    ap.id_pracownika = f.id_pracownika
    AND ap.data_rozpoczecia BETWEEN 
        (SELECT data_od FROM okresy_oceny WHERE id_okresu = f.id_okresu)
        AND 
        (SELECT data_do FROM okresy_oceny WHERE id_okresu = f.id_okresu);

CREATE OR REPLACE VIEW v_lista_pracownikow_combo AS
SELECT 
    -- Co widzi użytkownik: "Kowalski Jan (dr inż.)"
    p.nazwisko || ' ' || p.imie || ' (' || st.skrot || ')' AS wyswietlana_nazwa,
    p.id_pracownika
FROM 
    pracownicy p
JOIN 
    stopnie_tytuly st ON p.id_stopnia = st.id_stopnia
WHERE 
    p.czy_aktywny = TRUE
ORDER BY 
    p.nazwisko ASC, p.imie ASC;

CREATE OR REPLACE VIEW pcz_oceny.v_szczegoly_wybranego_pracownika AS
SELECT 
    f.nazwa_uzytkownika, -- Klucz łączenia z formularzem głównym
    p.id_pracownika,
    
    -- !!! TE DWIE KOLUMNY BYŁY BRAKUJĄCE !!!
    p.imie,
    p.nazwisko,
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    -- Reszta danych potrzebna do formularzy i raportów
    st.nazwa_stopnia AS stopien_pelny,
    s.nazwa_stanowiska,
    gs.nazwa_grupy AS grupa_stanowisk,
    jo.nazwa_jednostki AS nazwa_katedry,
	wd.nazwa_jednostki AS nazwa_wydzialu,
    we.opis_etatu,
    p.orcid,
    p.data_zatrudnienia
FROM 
    pcz_oceny.filtr_uzytkownika f
JOIN 
    pcz_oceny.pracownicy p ON f.id_pracownika = p.id_pracownika
LEFT JOIN 
    pcz_oceny.stopnie_tytuly st ON p.id_stopnia = st.id_stopnia
LEFT JOIN 
    pcz_oceny.stanowiska s ON p.id_stanowiska = s.id_stanowiska
LEFT JOIN 
    pcz_oceny.grupy_stanowisk gs ON p.id_grupy_stanowisk = gs.id_grupy_stanowisk
LEFT JOIN 
    pcz_oceny.jednostki_organizacyjne jo ON p.id_jednostki = jo.id_jednostki
LEFT JOIN
	pcz_oceny.jednostki_organizacyjne wd ON jo.id_jednostki_nadrzednej = wd.id_jednostki
LEFT JOIN 
    pcz_oceny.wymiar_etatu we ON p.id_etatu = we.id_etatu;

CREATE OR REPLACE VIEW v_aktywnosci_wybranego_pracownika AS
SELECT 
    ap.id_aktywnosci,
    f.nazwa_uzytkownika, -- Klucz filtra
    
    -- Dane do tabeli
    ap.data_rozpoczecia,
    gd.kod_grupy, -- np. PUB, DYD (do szybkiej identyfikacji wzrokowej)
    ta.nazwa_aktywnosci,
    ap.opis_szczegolowy,
    ap.przyznane_punkty,
    ap.udzial_procentowy
FROM 
    aktywnosci_pracownika ap
JOIN 
    filtr_uzytkownika f ON f.nazwa_uzytkownika = current_user
JOIN 
    typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu
JOIN 
    grupy_dzialan gd ON ta.id_grupy = gd.id_grupy
WHERE 
    ap.id_pracownika = f.id_pracownika
    AND ap.data_rozpoczecia >= (SELECT data_od FROM okresy_oceny WHERE id_okresu = f.id_okresu)
    AND ap.data_rozpoczecia <= (SELECT data_do FROM okresy_oceny WHERE id_okresu = f.id_okresu)
ORDER BY 
    ap.data_rozpoczecia DESC;

CREATE OR REPLACE VIEW pcz_oceny.v_podsumowanie_wertykalne AS
WITH 
-- 1. Pobieramy kontekst sesji (kogo i za jaki okres sprawdzamy)
sesja AS (
    SELECT nazwa_uzytkownika, id_pracownika, id_okresu 
    FROM pcz_oceny.filtr_uzytkownika 
    WHERE nazwa_uzytkownika = current_user
),
-- 2. Pobieramy dane pracownika (Etat jest kluczowy do wyliczeń!)
info_prac AS (
    SELECT 
        p.id_pracownika, 
        p.id_stanowiska, 
        p.id_grupy_stanowisk, 
        we.wartosc_liczbowa AS etat
    FROM pcz_oceny.pracownicy p
    JOIN pcz_oceny.wymiar_etatu we ON p.id_etatu = we.id_etatu
    JOIN sesja s ON p.id_pracownika = s.id_pracownika
),
-- 3. Pobieramy progi punktowe dla tego stanowiska i okresu
wymogi AS (
    SELECT kpp.*
    FROM pcz_oceny.konfiguracja_progi_punktowe kpp
    JOIN sesja s ON kpp.id_okresu = s.id_okresu
    JOIN info_prac ip ON kpp.id_stanowiska = ip.id_stanowiska 
        AND kpp.id_grupy_stanowisk = ip.id_grupy_stanowisk
),
-- 4. Sumujemy punkty, które pracownik już zdobył (grupując po ID grupy)
punkty_uzyskane AS (
    SELECT 
        ta.id_grupy,
        SUM(ap.przyznane_punkty) AS suma
    FROM pcz_oceny.aktywnosci_pracownika ap
    JOIN sesja s ON ap.id_pracownika = s.id_pracownika
    JOIN pcz_oceny.okresy_oceny oo ON s.id_okresu = oo.id_okresu
    JOIN pcz_oceny.typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu
    WHERE ap.data_rozpoczecia BETWEEN oo.data_od AND oo.data_do
    GROUP BY ta.id_grupy
)

-- 5. SKŁADANIE WYNIKU (Wiersze dla grup: PUB, DYD, ORG, BR)
SELECT 
    s.nazwa_uzytkownika,
    gd.id_grupy AS kolejnosc_sortowania, -- Żeby zachować kolejność z bazy
    gd.nazwa_grupy,
    
    -- Uzyskane (jeśli NULL to 0)
    COALESCE(pu.suma, 0) AS uzyskane,
    
    -- Wymagane (Logika mapowania kodów grup na kolumny z tabeli progów)
    -- Mnożymy przez ETAT!
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN (w.prog_punktowy_pub * ip.etat)
        WHEN gd.kod_grupy = 'DYD' THEN (w.prog_punktowy_dyd * ip.etat)
        WHEN gd.kod_grupy = 'ORG' THEN (w.prog_punktowy_org * ip.etat)
        ELSE 0.00 -- Dla BR zazwyczaj nie ma progu cząstkowego w tej tabeli
    END AS wymagane,
    
    -- Bilans (Ile brakuje)
    (COALESCE(pu.suma, 0) - 
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN (w.prog_punktowy_pub * ip.etat)
        WHEN gd.kod_grupy = 'DYD' THEN (w.prog_punktowy_dyd * ip.etat)
        WHEN gd.kod_grupy = 'ORG' THEN (w.prog_punktowy_org * ip.etat)
        ELSE 0.00
    END) AS bilans

FROM pcz_oceny.grupy_dzialan gd
CROSS JOIN sesja s
JOIN info_prac ip ON s.id_pracownika = ip.id_pracownika
LEFT JOIN wymogi w ON 1=1 -- Progi są jedne (1 wiersz), więc join jest bezpieczny
LEFT JOIN punkty_uzyskane pu ON gd.id_grupy = pu.id_grupy

UNION ALL

-- 6. DODATKOWY WIERSZ: SUMA CAŁKOWITA (TOTAL)
-- To jest wiersz podsumowujący, którego nie ma w tabeli grup, a jest kluczowy.
SELECT 
    s.nazwa_uzytkownika,
    999 AS kolejnosc_sortowania, -- Żeby był na samym dole
    'SUMA' AS nazwa_grupy,
    
    -- Suma wszystkiego co pracownik ma w tabeli aktywności
    (SELECT COALESCE(SUM(ap2.przyznane_punkty), 0)
     FROM pcz_oceny.aktywnosci_pracownika ap2
     JOIN pcz_oceny.okresy_oceny oo ON s.id_okresu = oo.id_okresu
     WHERE ap2.id_pracownika = s.id_pracownika
       AND ap2.data_rozpoczecia BETWEEN oo.data_od AND oo.data_do
    ) AS uzyskane,
    
    -- Wymóg całkowity * Etat
    (w.prog_punktowy_total * ip.etat) AS wymagane,
    
    -- Bilans całkowity
    ((SELECT COALESCE(SUM(ap2.przyznane_punkty), 0)
      FROM pcz_oceny.aktywnosci_pracownika ap2
      JOIN pcz_oceny.okresy_oceny oo ON s.id_okresu = oo.id_okresu
      WHERE ap2.id_pracownika = s.id_pracownika
        AND ap2.data_rozpoczecia BETWEEN oo.data_od AND oo.data_do) 
     - (w.prog_punktowy_total * ip.etat)) AS bilans

FROM sesja s
JOIN info_prac ip ON s.id_pracownika = ip.id_pracownika
LEFT JOIN wymogi w ON 1=1;

SET search_path TO pcz_oceny;

-- ================================================================
-- 1. TWORZENIE SŁOWNIKÓW (Uproszczone nazwy, brak konfiguracji)
-- ================================================================

-- A. Słownik ocen (np. Pozytywna, Negatywna)
CREATE TABLE IF NOT EXISTS skala_ocen (
    id_oceny SERIAL PRIMARY KEY,
    nazwa_oceny VARCHAR(50) NOT NULL UNIQUE,
    skrot_oceny VARCHAR(10)
);

-- B. Słownik decyzji odwoławczych (np. Utrzymuje w mocy...)
CREATE TABLE IF NOT EXISTS decyzje_odwolawcze (
    id_decyzji SERIAL PRIMARY KEY,
    tresc_decyzji TEXT NOT NULL UNIQUE
);

-- C. NOWOŚĆ: Słownik ról osoby oceniającej (do skreślania w nagłówku)
CREATE TABLE IF NOT EXISTS role_oceniajacych (
    id_roli SERIAL PRIMARY KEY,
    nazwa_roli VARCHAR(100) NOT NULL UNIQUE
);

-- ================================================================
-- 2. WYPEŁNIENIE DANYMI STARTOWYMI
-- ================================================================

-- Oceny
INSERT INTO skala_ocen (nazwa_oceny, skrot_oceny) VALUES 
('POZYTYWNA', 'POZ'),
('POZYTYWNA WARUNKOWA', 'WAR'),
('NEGATYWNA', 'NEG')
ON CONFLICT DO NOTHING;

-- Decyzje odwoławcze
INSERT INTO decyzje_odwolawcze (tresc_decyzji) VALUES
('Utrzymuje w mocy negatywną ocenę Komisji'),
('Utrzymuje w mocy pozytywną warunkową ocenę Komisji'),
('Zmienia ocenę na pozytywną warunkową'),
('Zmienia ocenę na pozytywną')
ON CONFLICT DO NOTHING;

-- Role oceniających (Dokładnie tak jak w druku, żeby wiedzieć co zostawić)
INSERT INTO role_oceniajacych (nazwa_roli) VALUES 
('Prodziekan ds. nauki'),
('Dziekan'),
('Kierownik jednostki międzywydziałowej')
ON CONFLICT DO NOTHING;


-- ================================================================
-- 3. MODYFIKACJA TABELI OCENY_OKRESOWE (FINALNA WERSJA)
-- ================================================================

-- A. SEKCJA KIEROWNIKA / PRODZIEKANA (Prefix: kier_)
ALTER TABLE oceny_okresowe 
ADD COLUMN kier_data_oceny DATE DEFAULT CURRENT_DATE,
ADD COLUMN kier_uzasadnienie_punktow TEXT,
ADD COLUMN kier_uzasadnienie_oceny TEXT,

-- Kto ocenia? (Do skreślania w raporcie)
ADD COLUMN kier_id_roli INT REFERENCES role_oceniajacych(id_roli),

-- Propozycje ocen (Klucze obce do tabeli skala_ocen)
ADD COLUMN kier_id_oceny_pub INT REFERENCES skala_ocen(id_oceny),
ADD COLUMN kier_id_oceny_br  INT REFERENCES skala_ocen(id_oceny),
ADD COLUMN kier_id_oceny_dyd INT REFERENCES skala_ocen(id_oceny),
ADD COLUMN kier_id_oceny_org INT REFERENCES skala_ocen(id_oceny),
ADD COLUMN kier_id_oceny_total INT REFERENCES skala_ocen(id_oceny);

-- B. SEKCJA KOMISJI UCZELNIANEJ (Prefix: kom_)
ALTER TABLE oceny_okresowe 
ADD COLUMN kom_data_oceny DATE,
ADD COLUMN kom_uzasadnienie TEXT,
ADD COLUMN kom_wniosek_zatrudnienie TEXT,
ADD COLUMN kom_id_oceny INT REFERENCES skala_ocen(id_oceny);

-- C. SEKCJA KOMISJI ODWOŁAWCZEJ (Prefix: odw_)
ALTER TABLE oceny_okresowe 
ADD COLUMN odw_czy_odwolanie BOOLEAN DEFAULT FALSE,
ADD COLUMN odw_data_odwolania DATE,
ADD COLUMN odw_data_decyzji DATE,
ADD COLUMN odw_uzasadnienie TEXT,
ADD COLUMN odw_id_decyzji INT REFERENCES decyzje_odwolawcze(id_decyzji),
ADD COLUMN odw_id_oceny INT REFERENCES skala_ocen(id_oceny);

CREATE OR REPLACE VIEW pcz_oceny.v_podglad_komisji AS
WITH 
-- 1. Pobieramy kontekst sesji (kogo i za jaki okres sprawdzamy)
sesja AS (
    SELECT nazwa_uzytkownika, id_pracownika, id_okresu 
    FROM pcz_oceny.filtr_uzytkownika 
    WHERE nazwa_uzytkownika = current_user
),
-- 2. Pobieramy dane pracownika (Etat jest kluczowy do wyliczeń wymogów)
info_prac AS (
    SELECT 
        p.id_pracownika, 
        p.id_stanowiska, 
        p.id_grupy_stanowisk, 
        we.wartosc_liczbowa AS etat
    FROM pcz_oceny.pracownicy p
    JOIN pcz_oceny.wymiar_etatu we ON p.id_etatu = we.id_etatu
    JOIN sesja s ON p.id_pracownika = s.id_pracownika
),
-- 3. Pobieramy progi punktowe dla tego stanowiska i okresu
wymogi AS (
    SELECT kpp.*
    FROM pcz_oceny.konfiguracja_progi_punktowe kpp
    JOIN sesja s ON kpp.id_okresu = s.id_okresu
    JOIN info_prac ip ON kpp.id_stanowiska = ip.id_stanowiska 
        AND kpp.id_grupy_stanowisk = ip.id_grupy_stanowisk
),
-- 4. NOWOŚĆ: Pobieramy ZAMROŻONE punkty i oceny z etapu kierownika
ocena_kier AS (
    SELECT o.*
    FROM pcz_oceny.oceny_okresowe o
    JOIN sesja s ON o.id_pracownika = s.id_pracownika AND o.id_okresu = s.id_okresu
)

-- 5. SKŁADANIE WYNIKU (Wiersze dla grup: PUB, DYD, ORG, BR)
SELECT 
    s.nazwa_uzytkownika,
    gd.id_grupy AS kolejnosc_sortowania,
    gd.nazwa_grupy,
    
    -- Zamrożone uzyskane punkty pobrane z bazy (Zamiast liczenia w locie)
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN COALESCE(ok.suma_pkt_pub, 0)
        WHEN gd.kod_grupy = 'DYD' THEN COALESCE(ok.suma_pkt_dyd, 0)
        WHEN gd.kod_grupy = 'ORG' THEN COALESCE(ok.suma_pkt_org, 0)
        WHEN gd.kod_grupy = 'BR'  THEN COALESCE(ok.suma_pkt_br, 0) -- Jeśli masz taką kolumnę
        ELSE 0
    END AS uzyskane,
    
    -- Wymagane (Mnożymy przez ETAT)
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN (w.prog_punktowy_pub * ip.etat)
        WHEN gd.kod_grupy = 'DYD' THEN (w.prog_punktowy_dyd * ip.etat)
        WHEN gd.kod_grupy = 'ORG' THEN (w.prog_punktowy_org * ip.etat)
        ELSE 0.00 
    END AS wymagane,
    
    -- Bilans (Zamrożone uzyskane - Wymagane etatowe)
    (
        CASE 
            WHEN gd.kod_grupy = 'PUB' THEN COALESCE(ok.suma_pkt_pub, 0)
            WHEN gd.kod_grupy = 'DYD' THEN COALESCE(ok.suma_pkt_dyd, 0)
            WHEN gd.kod_grupy = 'ORG' THEN COALESCE(ok.suma_pkt_org, 0)
            WHEN gd.kod_grupy = 'BR'  THEN COALESCE(ok.suma_pkt_br, 0)
            ELSE 0
        END 
        - 
        CASE 
            WHEN gd.kod_grupy = 'PUB' THEN (w.prog_punktowy_pub * ip.etat)
            WHEN gd.kod_grupy = 'DYD' THEN (w.prog_punktowy_dyd * ip.etat)
            WHEN gd.kod_grupy = 'ORG' THEN (w.prog_punktowy_org * ip.etat)
            ELSE 0.00
        END
    ) AS bilans,

    -- NOWOŚĆ: Słowna ocena cząstkowa wystawiona przez kierownika
    so.nazwa_oceny AS ocena_kierownika

FROM pcz_oceny.grupy_dzialan gd
CROSS JOIN sesja s
JOIN info_prac ip ON s.id_pracownika = ip.id_pracownika
LEFT JOIN wymogi w ON 1=1 
LEFT JOIN ocena_kier ok ON 1=1
-- Inteligentne złączenie ze słownikiem ocen na podstawie kodu grupy
LEFT JOIN pcz_oceny.skala_ocen so ON so.id_oceny = 
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN ok.kier_id_oceny_pub
        WHEN gd.kod_grupy = 'DYD' THEN ok.kier_id_oceny_dyd
        WHEN gd.kod_grupy = 'ORG' THEN ok.kier_id_oceny_org
        WHEN gd.kod_grupy = 'BR'  THEN ok.kier_id_oceny_br  -- <--- DODANA LINIJKA
        ELSE NULL
    END

UNION ALL

-- 6. DODATKOWY WIERSZ: SUMA CAŁKOWITA (TOTAL) Z OCENĄ KOŃCOWĄ
SELECT 
    s.nazwa_uzytkownika,
    999 AS kolejnosc_sortowania,
    'SUMA' AS nazwa_grupy,
    
    -- Zamrożona suma wszystkich punktów
    COALESCE(ok.suma_pkt_total, 0) AS uzyskane,
    
    -- Wymóg całkowity * Etat
    (w.prog_punktowy_total * ip.etat) AS wymagane,
    
    -- Bilans całkowity
    (COALESCE(ok.suma_pkt_total, 0) - (w.prog_punktowy_total * ip.etat)) AS bilans,

    -- NOWOŚĆ: Końcowa ocena zaproponowana przez kierownika
    so_total.nazwa_oceny AS ocena_kierownika

FROM sesja s
JOIN info_prac ip ON s.id_pracownika = ip.id_pracownika
LEFT JOIN wymogi w ON 1=1
LEFT JOIN ocena_kier ok ON 1=1
-- Pobieramy ocenę całkowitą (TOTAL)
LEFT JOIN pcz_oceny.skala_ocen so_total ON so_total.id_oceny = ok.kier_id_oceny_total;

CREATE OR REPLACE VIEW v_podglad_odwolanie AS
SELECT 
	oo.id_pracownika,
	oo.id_okresu,
	oo.kier_uzasadnienie_punktow,
	oo.kier_uzasadnienie_oceny,
	kom_uzasadnienie,
	kom_wniosek_zatrudnienie,
	ko.nazwa_oceny AS kom_ocena
FROM oceny_okresowe oo
LEFT JOIN skala_ocen ko ON oo.kom_id_oceny = ko.id_oceny;
