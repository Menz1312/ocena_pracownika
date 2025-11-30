-- 1. Utworzenie schematu (jeśli jeszcze nie istnieje)
CREATE SCHEMA IF NOT EXISTS oceny_pracownikow;

-- 2. Ustawienie domyślnej ścieżki wyszukiwania na nowym schemacie
-- Od teraz wszystkie tabele będą tworzone w 'oceny_pracownikow'
SET search_path TO oceny_pracownikow;

----------------------------------------------------
-- GRUPA 3 (Słowniki centralne - tworzone najpierw)
----------------------------------------------------

CREATE TABLE sl_grupy_dzialan (
    id_grupy SERIAL PRIMARY KEY,
    nazwa_grupy VARCHAR(100) NOT NULL,
    kod_grupy VARCHAR(10) NOT NULL UNIQUE -- np. 'PUB', 'BR', 'DYD', 'ORG'
);

CREATE TABLE sl_typy_aktywnosci (
    id_typu_aktywnosci SERIAL PRIMARY KEY,
    id_grupy INT NOT NULL REFERENCES sl_grupy_dzialan(id_grupy),
    lp VARCHAR(10), -- Numer Lp. z arkusza, np. "1.", "16."
    nazwa_parametru TEXT NOT NULL,
    punkty_domyslne NUMERIC(5, 2), -- Wartość stała
    punkty_min NUMERIC(5, 2),      -- Dolny limit walidacji
    punkty_max NUMERIC(5, 2),       -- Górny limit walidacji
	czy_ciagla BOOLEAN DEFAULT FALSE	-- TRUE dla funkcji (dziekan, opiekun koła), FALSE dla publikacji
);

----------------------------------------------------
-- GRUPA 1 (Struktura uczelni i pracownika)
----------------------------------------------------

CREATE TABLE jednostki_organizacyjne (
    id_jednostki SERIAL PRIMARY KEY,
    nazwa_jednostki VARCHAR(255) NOT NULL, -- Np. "Wydział Zarządzania"
    id_jednostki_nadrzednej INT REFERENCES jednostki_organizacyjne(id_jednostki) -- Do tworzenia drzewa (Wydział -> Katedra)
    -- Usunęliśmy pole 'schemat', które było niejasne
);

CREATE TABLE typy_stanowisk (
    id_typu_stanowiska SERIAL PRIMARY KEY,
    nazwa_typu VARCHAR(100) NOT NULL, -- "badawczo-dydaktyczny", "badawczy", "dydaktyczny"
    prog_punktowy_pub NUMERIC(6, 2),  -- Roczny próg za publikacje
    prog_punktowy_inny NUMERIC(6, 2), -- Roczny próg za inne (dla dydaktycznych)
    prog_punktowy_total NUMERIC(6, 2) -- Roczny próg łączny (np. 100)
);

CREATE TABLE stopnie_naukowe (
    id_stopnia SERIAL PRIMARY KEY,
    nazwa_stopnia VARCHAR(50) NOT NULL -- "dr", "dr hab.", "prof."
);

CREATE TABLE pracownicy (
    id_pracownika SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    orcid VARCHAR(19) UNIQUE,
    data_zatrudnienia DATE,
    
    -- Poprawiona nazwa klucza obcego
    id_jednostki INT REFERENCES jednostki_organizacyjne(id_jednostki), 
    
    id_typu_stanowiska INT REFERENCES typy_stanowisk(id_typu_stanowiska),
    id_stopnia INT REFERENCES stopnie_naukowe(id_stopnia)
);

----------------------------------------------------
-- GRUPA 2 (Dyscypliny i deklaracje)
----------------------------------------------------

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
    id_dyscypliny INT NOT NULL REFERENCES dyscypliny(id_dyscypliny),
    udzial_procentowy NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    CONSTRAINT chk_udzial_procentowy CHECK (udzial_procentowy > 0 AND udzial_procentowy <= 100)
);

----------------------------------------------------
-- GRUPA 3 (Tabele faktów - oceny i aktywności)
----------------------------------------------------

CREATE TABLE aktywnosci_pracownika (
    id_aktywnosci SERIAL PRIMARY KEY,
    id_pracownika INT NOT NULL REFERENCES pracownicy(id_pracownika),
    id_typu_aktywnosci INT NOT NULL REFERENCES sl_typy_aktywnosci(id_typu_aktywnosci),
    data_rozpoczecia DATE NOT NULL, -- Dla publikacji to data wydania
    data_zakonczenia DATE,          -- NULL dla zdarzeń jednorazowych (publikacje, nagrody)
    przyznane_punkty NUMERIC(6, 2) NOT NULL, -- Wyliczona (lub wpisana) wartość
    opis_szczegolowy TEXT
);

CREATE TABLE oceny_okresowe (
    id_oceny SERIAL PRIMARY KEY,
    id_pracownika INT NOT NULL REFERENCES pracownicy(id_pracownika),
    okres_od DATE NOT NULL,
    okres_do DATE NOT NULL,
    data_oceny DATE NOT NULL,
    wynik_koncowy VARCHAR(50), -- "pozytywna", "negatywna", "pozytywna warunkowa"
    suma_pkt_pub NUMERIC(6, 2), -- Suma z grupy 'PUB'
    suma_pkt_br NUMERIC(6, 2),  -- Suma z grupy 'BR' (Dodane)
    suma_pkt_dyd NUMERIC(6, 2), -- Suma z grupy 'DYD' (Poprawiona literówka)
    suma_pkt_org NUMERIC(6, 2), -- Suma z grupy 'ORG'
    suma_pkt_total NUMERIC(7, 2), -- Suma całkowita
    uzasadnienie TEXT
);