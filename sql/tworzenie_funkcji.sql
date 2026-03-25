CREATE OR REPLACE FUNCTION pcz_oceny.f_podsumowanie_wertykalne(p_pracownik INT, p_okres INT, p_data_od DATE, p_data_do DATE)
RETURNS TABLE (
    nazwa_uzytkownika TEXT,
    kolejnosc_sortowania INT,
    nazwa_grupy TEXT,
    uzyskane NUMERIC,
    wymagane NUMERIC,
    bilans NUMERIC
) AS $$
WITH info_prac AS (
    SELECT p.id_pracownika, p.id_stanowiska, p.id_grupy_stanowisk, we.wartosc_liczbowa AS etat
    FROM pcz_oceny.pracownicy p
    JOIN pcz_oceny.wymiar_etatu we ON p.id_etatu = we.id_etatu
    WHERE p.id_pracownika = p_pracownik
),
wymogi AS (
    SELECT kpp.*
    FROM pcz_oceny.konfiguracja_progi_punktowe kpp
    JOIN info_prac ip ON kpp.id_stanowiska = ip.id_stanowiska AND kpp.id_grupy_stanowisk = ip.id_grupy_stanowisk
    WHERE kpp.id_okresu = p_okres
),
surowe_dane AS (
    SELECT 
        ap.id_aktywnosci, ap.id_typu_aktywnosci, ta.id_grupy, ap.przyznane_punkty,
        EXTRACT(YEAR FROM ap.data_rozpoczecia) AS rok,
        -- Flaga 1: Artykuły (id 1,2) za <= 20 pkt
        CASE WHEN ap.id_typu_aktywnosci IN (1, 2) AND ap.przyznane_punkty <= 20 THEN 1 ELSE 0 END AS reg1,
        -- Flaga 2: Monografie (id 3,4,5) niezależnie od punktów
        CASE WHEN ap.id_typu_aktywnosci IN (3, 4, 5) THEN 1 ELSE 0 END AS reg2
    FROM pcz_oceny.aktywnosci_pracownika ap
    JOIN pcz_oceny.typy_aktywnosci ta ON ap.id_typu_aktywnosci = ta.id_typu
    WHERE ap.id_pracownika = p_pracownik 
      AND ap.data_rozpoczecia >= p_data_od AND ap.data_rozpoczecia <= p_data_do
),
rankingowane AS (
    -- Numerujemy wiersze w ramach danego roku i reguły (od najwyżej punktowanej)
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY rok, reg1 ORDER BY przyznane_punkty DESC) AS rn1,
        ROW_NUMBER() OVER(PARTITION BY rok, reg2 ORDER BY przyznane_punkty DESC) AS rn2
    FROM surowe_dane
),
punkty_uzyskane AS (
    SELECT id_grupy, SUM(przyznane_punkty) AS suma
    FROM rankingowane
    -- Zostawiamy normalne wpisy ORAZ tylko te z pozycją nr 1 dla limitowanych reguł
    WHERE (reg1 = 0 OR rn1 = 1) AND (reg2 = 0 OR rn2 = 1)
    GROUP BY id_grupy
),
punkty_total AS (
    SELECT COALESCE(SUM(suma), 0) AS suma_calkowita FROM punkty_uzyskane
)

-- SKŁADANIE WYNIKÓW DLA POSZCZEGÓLNYCH GRUP
SELECT 
    current_user::TEXT AS nazwa_uzytkownika, gd.id_grupy AS kolejnosc_sortowania, gd.nazwa_grupy::TEXT,
    COALESCE(pu.suma, 0) AS uzyskane,
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN COALESCE(w.prog_punktowy_pub * ip.etat, 0)
        WHEN gd.kod_grupy = 'DYD' THEN COALESCE(w.prog_punktowy_dyd * ip.etat, 0)
        WHEN gd.kod_grupy = 'ORG' THEN COALESCE(w.prog_punktowy_org * ip.etat, 0)
        ELSE 0.00 
    END AS wymagane,
    (COALESCE(pu.suma, 0) - 
    CASE 
        WHEN gd.kod_grupy = 'PUB' THEN COALESCE(w.prog_punktowy_pub * ip.etat, 0)
        WHEN gd.kod_grupy = 'DYD' THEN COALESCE(w.prog_punktowy_dyd * ip.etat, 0)
        WHEN gd.kod_grupy = 'ORG' THEN COALESCE(w.prog_punktowy_org * ip.etat, 0)
        ELSE 0.00 
    END) AS bilans
FROM pcz_oceny.grupy_dzialan gd
CROSS JOIN info_prac ip
LEFT JOIN wymogi w ON 1=1
LEFT JOIN punkty_uzyskane pu ON gd.id_grupy = pu.id_grupy

UNION ALL

-- DODATKOWY WIERSZ: SUMA CAŁKOWITA
SELECT 
    current_user::TEXT AS nazwa_uzytkownika, 999 AS kolejnosc_sortowania, 'SUMA' AS nazwa_grupy,
    pt.suma_calkowita AS uzyskane, COALESCE(w.prog_punktowy_total * ip.etat, 0) AS wymagane,
    (pt.suma_calkowita - COALESCE(w.prog_punktowy_total * ip.etat, 0)) AS bilans
FROM info_prac ip
CROSS JOIN punkty_total pt
LEFT JOIN wymogi w ON 1=1;
$$ LANGUAGE sql;