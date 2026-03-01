SET search_path TO pcz_oceny;

INSERT INTO okresy_oceny (nazwa_okresu, data_od, data_do, czy_aktywny) 
VALUES ('2023-2025', '2023-01-01', '2025-12-31', TRUE);

INSERT INTO grupy_dzialan (nazwa_grupy, kod_grupy) VALUES
('Działalność publikacyjna (art. i monografie)', 'PUB'),
('Działalność B+R', 'BR'),
('Działalność dydaktyczna', 'DYD'),
('Działalność organizacyjna i pozostałe', 'ORG');

INSERT INTO grupy_stanowisk (nazwa_grupy) VALUES 
('Badawczo-dydaktyczny'),
('Badawczy'),
('Dydaktyczny');

INSERT INTO stanowiska (nazwa_stanowiska) VALUES 
('Profesor'),
('Profesor Uczelni'),
('Adiunkt'),
('Asystent');

INSERT INTO konfiguracja_progi_punktowe 
(id_okresu, id_grupy_stanowisk, id_stanowiska, prog_punktowy_total, prog_punktowy_pub, prog_punktowy_dyd)
SELECT 
    (SELECT id_okresu FROM okresy_oceny LIMIT 1),
    g.id_grupy_stanowisk,
    s.id_stanowiska,
    -- Wyliczenie progu TOTAL (Standard: 100, Asystent: 75)
    CASE WHEN s.nazwa_stanowiska = 'Asystent' THEN 75.00 ELSE 100.00 END as total,
    -- Wyliczenie progu PUB (Tylko dla badawczych/bad-dyd)
    CASE 
        WHEN g.nazwa_grupy = 'Badawczy' AND s.nazwa_stanowiska = 'Asystent' THEN 60.00 -- (80 * 0.75)
        WHEN g.nazwa_grupy = 'Badawczy' THEN 80.00
        WHEN g.nazwa_grupy = 'Badawczo-dydaktyczny' AND s.nazwa_stanowiska = 'Asystent' THEN 45.00 -- (60 * 0.75)
        WHEN g.nazwa_grupy = 'Badawczo-dydaktyczny' THEN 60.00
        ELSE 0.00 
    END as pub,
    CASE 
        WHEN g.nazwa_grupy = 'Dydaktyczny' AND s.nazwa_stanowiska = 'Asystent' THEN 60.00 -- (80 * 0.75)
        WHEN g.nazwa_grupy = 'Dydaktyczny' THEN 80.00
        ELSE 0.00 
    END as dyd
FROM grupy_stanowisk g CROSS JOIN stanowiska s;

INSERT INTO wymiar_etatu (opis_etatu, wartosc_liczbowa, kolejnosc) VALUES 
('Pełny etat',	1.000, 10),
('7/8 etatu', 	0.875, 20),
('4/5 etatu', 	0.800, 30),
('3/4 etatu',  	0.750, 40),
('2/3 etatu', 	0.667, 50),
('3/5 etatu',	0.600, 60),
('1/2 etatu',  	0.500, 70),
('2/5 etatu',	0.400, 80),
('1/3 etatu',	0.333, 90),
('1/4 etatu',  	0.250, 100),
('1/5 etatu',	0.200, 110),
('1/8 etatu',  	0.125, 120);

INSERT INTO stopnie_tytuly (nazwa_stopnia, skrot) VALUES
('magister', 'mgr'),
('magister inżynier', 'mgr inż.'),
('doktor', 'dr'),
('doktor inżynier', 'dr inż.'),
('doktor habilitowany', 'dr hab.'),
('doktor habilitowany inżynier', 'dr hab. inż.'),
('profesor dr hab.', 'prof. dr hab.'),
('profesor dr hab. inż.', 'prof. dr hab. inż.');

INSERT INTO typy_aktywnosci (nazwa_aktywnosci, id_grupy, czy_ciagla, czy_udzial) VALUES

-- === Grupa 1: Działalność publikacyjna ===
('Publikacja w czasopiśmie naukowym wymienionym w wykazie właściwego ministra', 1, FALSE, TRUE),
('Publikacja w recenzowanych materiałach z konferencji międzynarodowej wymienionej w wykazie właściwego ministra', 1, FALSE, TRUE),
('Monografia naukowa wydana przez wydawnictwa wymienione w wykazie właściwego ministra', 1, FALSE, TRUE),
('Rozdział w monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', 1, FALSE, TRUE),
('Redakcja monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', 1, FALSE, TRUE),

-- === Grupa 2: Działalność B+R ===
('Przyznany PCz patent europejski albo patent przyznany za granicą...', 2, FALSE, TRUE),
('Patent przyznany PCz przez Urząd Patentowy Rzeczypospolitej Polskiej', 2, FALSE, TRUE),
('Patent przyznany innemu podmiotowi niż PCz (autor pracownik PCz)', 2, FALSE, TRUE),
('Prawa ochronne na wzór użytkowy przyznane PCz...', 2, FALSE, TRUE),

-- Projekty B+R (PCz lider) - wymagają oświadczenia o podziale (TRUE)
('Projekt B+R (PCz lider): Finansowany z budżetu UE, EFTA lub zagraniczne bezzwrotne', 2, TRUE, TRUE),
('Projekt B+R (PCz lider): Finansowany przez NCBIR (obronność/bezpieczeństwo)', 2, TRUE, TRUE),
('Projekt B+R (PCz lider): Finansowany przez NCN', 2, TRUE, TRUE),
('Projekt B+R (PCz lider): Finansowany przez FNP', 2, TRUE, TRUE),
('Projekt B+R (PCz lider): Finansowany przez NAWA', 2, TRUE, TRUE),

-- Projekty B+R (PCz partner) - wymagają oświadczenia o podziale (TRUE)
('Projekt B+R (PCz partner): Finansowany z budżetu UE, EFTA lub zagraniczne bezzwrotne', 2, TRUE, TRUE),
('Projekt B+R (PCz partner): Finansowany przez NCBIR (obronność/bezpieczeństwo)', 2, TRUE, TRUE),
('Projekt B+R (PCz partner): Finansowany przez NCN', 2, TRUE, TRUE),
('Projekt B+R (PCz partner): Finansowany przez FNP', 2, TRUE, TRUE),
('Projekt B+R (PCz partner): Finansowany przez NAWA', 2, TRUE, TRUE),

('Komercjalizacja wyników badań / usługi badawcze (dla podmiotów spoza szkolnictwa)', 2, FALSE, TRUE),
('Realizacja projektów oraz badań zleconych i usługowych', 2, TRUE, TRUE),

-- Przychody z wdrożeń - wymagają oświadczenia (TRUE)
('Przychody z wdrożeń: powyżej 5 mln zł', 2, FALSE, TRUE),
('Przychody z wdrożeń: powyżej 2,5 mln zł do 5 mln zł', 2, FALSE, TRUE),
('Przychody z wdrożeń: powyżej 0,5 mln zł do 2,5 mln zł', 2, FALSE, TRUE),
('Przychody z wdrożeń: od 25 tys. zł do 0,5 mln zł', 2, FALSE, TRUE),

('Udział w zespołach badawczych (za każdy udział)', 2, TRUE, TRUE),
('Udział w zespołach badawczych interdyscyplinarnych (za każdy udział)', 2, TRUE, TRUE),

-- === Grupa 3: Działalność dydaktyczna ===
-- Podręczniki - punkty dzielone równo (TRUE)
('Autorstwo podręcznika akademickiego/skryptu', 3, FALSE, TRUE),
('Autorstwo rozdziału w podręczniku akademickim/skrypcie', 3, FALSE, TRUE),
('Redakcja wieloautorskiego podręcznika akademickiego/skryptu', 3, FALSE, TRUE),

-- Oceny i ankiety - indywidualne (FALSE)
('Ocena na podstawie ankiet studentów i doktorantów', 3, FALSE, FALSE),
('Ocena z hospitacji zajęć dydaktycznych', 3, FALSE, FALSE),
('Liczba godzin w pensum dydaktycznym', 3, FALSE, FALSE),

-- Promotorstwo - zazwyczaj przypisane do osoby (FALSE), chyba że pomocniczy, ale tu traktujemy jako rolę
('Funkcja promotora rozprawy doktorskiej (rocznie)', 3, TRUE, FALSE),
('Funkcja promotora rozprawy doktorskiej (zakończona nadaniem stopnia)', 3, FALSE, FALSE),
('Funkcja promotora pomocniczego rozprawy doktorskiej (rocznie)', 3, TRUE, FALSE),
('Funkcja promotora pomocniczego rozprawy doktorskiej (zakończona nadaniem stopnia)', 3, FALSE, FALSE),
('Udział w komisji egzaminacyjnej w przewodzie doktorskim', 3, FALSE, FALSE),

('Promotorstwo pracy magisterskiej', 3, FALSE, FALSE),
('Promotorstwo pracy inżynierskiej / licencjackiej', 3, FALSE, FALSE),
('Recenzja pracy magisterskiej', 3, FALSE, FALSE),
('Recenzja pracy inżynierskiej / licencjackiej', 3, FALSE, FALSE),

-- Koordynatorzy - regulamin mówi o podziale zgodnym z oświadczeniem dla zespołu (TRUE)
('Koordynator uczelniany projektu dydaktycznego/inwestycyjnego', 3, TRUE, TRUE),
('Koordynator wydziałowy projektu dydaktycznego/inwestycyjnego', 3, TRUE, TRUE),
('Koordynator zadania / członek zespołu w projekcie dydaktycznym', 3, TRUE, TRUE),

-- Nowe programy/lab - regulamin mówi o podziale zgodnym z oświadczeniem (TRUE)
('Autorstwo programu nowego przedmiotu', 3, FALSE, TRUE),
('Przygotowanie i uruchomienie nowego laboratorium', 3, FALSE, TRUE),
('Opracowanie nowego kierunku studiów', 3, FALSE, TRUE),

('Opieka nad działającym kołem naukowym', 3, TRUE, FALSE),
('Podniesienie kwalifikacji zawodowych (udział w szkoleniu/kursie)', 3, FALSE, FALSE),
('Prowadzenie kursów i szkoleń podnoszących kwalifikacje', 3, FALSE, FALSE),
('Opieka nad laboratorium', 3, TRUE, FALSE),
('Udział w międzynarodowych programach wymiany akademickiej', 3, FALSE, FALSE),

-- === Grupa 4: Działalność organizacyjna ===
-- Funkcje jednoosobowe (FALSE)
('Funkcja prorektora', 4, TRUE, FALSE),
('Funkcja dziekana', 4, TRUE, FALSE),
('Funkcja kierownika szkoły doktorskiej, prodziekana ds. dydaktycznych, prodziekana ds. rozwoju, kierownika jednostki wydziałowej', 4, TRUE, FALSE),
('Funkcja zastępcy: prodziekana ds. dydaktycznych, kierownika jednostki międzywydziałowej, kierownika katedry', 4, TRUE, FALSE),
('Funkcja zastępcy kierownika katedry', 4, TRUE, FALSE),
('Pełnienie funkcji pełnomocnika lub koordynatora rektora', 4, TRUE, FALSE),
('Pełnienie funkcji pełnomocnika lub koordynatora dziekana', 4, TRUE, FALSE),
('Pełnienie funkcji kierownika studiów doktoranckich lub kierownika biura studentów zagranicznych', 4, TRUE, FALSE),

('Udział z wyboru we władzach centralnych towarzystw naukowych', 4, TRUE, FALSE),
('Udział z wyboru we władzach centralnych związków i organizacji branżowych krajowych', 4, TRUE, FALSE),
('Udział z wyboru we władzach centralnych związków i organizacji branżowych regionalnych', 4, TRUE, FALSE),

-- Konferencje - regulamin mówi o podziale punktów dla członków zespołu (TRUE)
('Organizacja międzynarodowej konferencji naukowej/dydaktycznej: przewodniczący komitetu', 4, FALSE, TRUE),
('Organizacja międzynarodowej konferencji naukowej/dydaktycznej: sekretarz lub zastępca przewodniczącego', 4, FALSE, TRUE),
('Organizacja międzynarodowej konferencji naukowej/dydaktycznej: członek komitetu', 4, FALSE, TRUE),

('Organizacja krajowej konferencji naukowej/dydaktycznej: przewodniczący komitetu', 4, FALSE, TRUE),
('Organizacja krajowej konferencji naukowej/dydaktycznej: sekretarz lub zastępca przewodniczącego', 4, FALSE, TRUE),
('Organizacja krajowej konferencji naukowej/dydaktycznej: członek komitetu', 4, FALSE, TRUE),

('Organizacja konferencji studenckiej: przewodniczący komitetu', 4, FALSE, TRUE),
('Organizacja konferencji studenckiej: sekretarz komitetu', 4, FALSE, TRUE),
('Organizacja konferencji studenckiej: członek komitetu', 4, FALSE, TRUE),

-- Organizacja kursów/olimpiad - zazwyczaj przypisane konkretne punkty za imprezę (FALSE, brak wzmianki o oświadczeniu w pkt 45)
('Organizacja i przeprowadzenie kursów studenckich, olimpiad przedmiotowych', 4, FALSE, FALSE),
('Organizacja i przeprowadzenie konkursów zewnętrznych', 4, FALSE, FALSE),
('Organizacja i przeprowadzenie zajęć dla szkół średnich, uczelnianych rozgrywek sportowych, uczelnianych konkursów tematycznych, wycieczek dydaktycznych', 4, FALSE, FALSE),

-- Nagrody indywidualne (FALSE)
('Nagroda prezydenta, premiera', 4, FALSE, FALSE),
('Nagroda ministra', 4, FALSE, FALSE),
('Nagroda marszałka województwa, wojewody, prezydenta miasta', 4, FALSE, FALSE),
('Promotorstwo wyróżnionych lub nagrodzonych prac: poziom międzynarodowy', 4, FALSE, FALSE),
('Promotorstwo wyróżnionych lub nagrodzonych prac: poziom krajowy', 4, FALSE, FALSE),
('Promotorstwo wyróżnionych lub nagrodzonych prac: poziom regionalny', 4, FALSE, FALSE),
('Promotorstwo wyróżnionych lub nagrodzonych prac: poziom uczelniany', 4, FALSE, FALSE),
('Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie międzynarodowym', 4, FALSE, FALSE),
('Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie krajowym', 4, FALSE, FALSE),
('Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie regionalnym', 4, FALSE, FALSE),

-- Nagrody edukacyjne - regulamin wspomina o podziale punktów między członków zespołu (TRUE)
('Nagrody przyznawane przez zagraniczne instytucje edukacyjne', 4, FALSE, TRUE),
('Nagrody przyznawane przez krajowe instytucje edukacyjne', 4, FALSE, TRUE),

('Członkostwo w komisjach rektorskich/senackich (bez funkcji)', 4, TRUE, FALSE),
('Przewodniczenie w komisjach rektorskich/senackich', 4, TRUE, FALSE),

-- Komisja Jakości Kształcenia - członek dzieli punkty wg oświadczenia (TRUE), przewodniczący ma stałe (FALSE)
('Komisja Jakości Kształcenia (Uczelniana): Członek', 4, TRUE, TRUE),
('Komisja Jakości Kształcenia (Wydziałowa): Członek', 4, TRUE, TRUE),
('Komisja Jakości Kształcenia (Uczelniana): Przewodniczący', 4, TRUE, FALSE),
('Komisja Jakości Kształcenia (Wydziałowa): Przewodniczący', 4, TRUE, FALSE),

('Komisja Rekrutacyjna: Wydziałowa', 4, FALSE, FALSE),
('Komisja Rekrutacyjna: Doktorancka', 4, FALSE, FALSE),
('Opiekun praktyk studenckich', 4, TRUE, FALSE),
('Opiekun roku studenckiego', 4, TRUE, FALSE),

-- Zespoły zadaniowe - podział wg oświadczenia (TRUE)
('Członkostwo w komisjach powołanych przez kierownika', 4, TRUE, TRUE),

('Władze zagraniczne/międzynarodowe towarzystw naukowych', 4, TRUE, FALSE),
('Władze krajowe towarzystw naukowych', 4, TRUE, FALSE),
('Członkostwo w PAN', 4, TRUE, FALSE),
('Członkostwo w komitecie PAN', 4, TRUE, FALSE),
('Członek stowarzyszony z sekcją PAN, ekspert', 4, TRUE, FALSE),
('Członek komisji PAN', 4, TRUE, FALSE),
('Działalność w panelach instytucji centralnych (PKA, RDN, NCN)', 4, TRUE, FALSE),
('Działalność w instytucjach regionalnych', 4, TRUE, FALSE),
('Udział w targach: Międzynarodowych', 4, FALSE, FALSE),
('Udział w targach: Krajowych', 4, FALSE, FALSE),
('Redaktor czasopisma naukowego', 4, TRUE, FALSE),
('Redaktor numeru czasopisma naukowego', 4, FALSE, FALSE),
('Wystąpienia w mediach jako ekspert', 4, FALSE, FALSE),
('Tłumaczenia / korekty językowe (SJO)', 4, FALSE, FALSE),
('Organizacja Dni Sportu / imprez kulturalnych', 4, FALSE, FALSE),
('Inne działania promocyjne', 4, FALSE, FALSE),
('Inne prace organizacyjne', 4, FALSE, FALSE);

INSERT INTO dziedziny (nazwa_dziedziny) VALUES
('nauki humanistyczne'),
('nauki inżynieryjno-techniczne'),
('nauki medyczne i nauki o zdrowiu'),
('nauki o rodzinie'),
('nauki rolnicze'),
('nauki społeczne'),
('nauki ścisłe i przyrodnicze'),
('nauki teologiczne'),
('nauki weterynaryjne'),
('sztuka');

INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(1, 'archeologia'),
(1, 'etnologia i antropologia kulturowa'),
(1, 'filozofia'),
(1, 'historia'),
(1, 'językoznawstwo'),
(1, 'literaturoznawstwo'),
(1, 'nauki o kulturze i religii'),
(1, 'nauki o sztuce'),
(1, 'polonistyka'); -- (polonistyka jest w, ale nie w)

-- Dziedzina: nauki inżynieryjno-techniczne (ID: 2)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(2, 'architektura i urbanistyka'),
(2, 'automatyka, elektronika, elektrotechnika i technologie kosmiczne'),
(2, 'informatyka techniczna i telekomunikacja'),
(2, 'inżynieria bezpieczeństwa'),
(2, 'inżynieria biomedyczna'),
(2, 'inżynieria chemiczna'),
(2, 'inżynieria lądowa, geodezja i transport'),
(2, 'inżynieria materiałowa'),
(2, 'inżynieria mechaniczna'),
(2, 'inżynieria środowiska, górnictwo i energetyka'),
(2, 'ochrona dziedzictwa i konserwacja zabytków');

-- Dziedzina: nauki medyczne i nauki o zdrowiu (ID: 3)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(3, 'biologia medyczna'),
(3, 'biotechnologia'), -- (biotechnologia jest w w tej dziedzinie)
(3, 'nauki farmaceutyczne'),
(3, 'nauki medyczne'),
(3, 'nauki o kulturze fizycznej'),
(3, 'nauki o zdrowiu');

-- Dziedzina: nauki o rodzinie (ID: 4)
-- Ta dziedzina jest jednocześnie dyscypliną
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(4, 'nauki o rodzinie');

-- Dziedzina: nauki rolnicze (ID: 5)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(5, 'nauki leśne'),
(5, 'rolnictwo i ogrodnictwo'),
(5, 'technologia żywności i żywienia'),
(5, 'zootechnika i rybactwo');

-- Dziedzina: nauki społeczne (ID: 6)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(6, 'ekonomia i finanse'),
(6, 'geografia społeczno-ekonomiczna i gospodarka przestrzenna'),
(6, 'nauki o bezpieczeństwie'),
(6, 'nauki o komunikacji społecznej i mediach'),
(6, 'nauki o polityce i administracji'),
(6, 'nauki o zarządzaniu i jakości'),
(6, 'nauki prawne'),
(6, 'nauki socjologiczne'),
(6, 'pedagogika'),
(6, 'psychologia'),
(6, 'stosunki międzynarodowe');

-- Dziedzina: nauki ścisłe i przyrodnicze (ID: 7)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(7, 'astronomia'),
(7, 'biotechnologia'),
(7, 'informatyka'),
(7, 'matematyka'),
(7, 'nauki biologiczne'),
(7, 'nauki chemiczne'),
(7, 'nauki fizyczne'),
(7, 'nauki o Ziemi i środowisku');

-- Dziedzina: nauki teologiczne (ID: 8)
-- Ta dziedzina jest jednocześnie dyscypliną
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(8, 'nauki teologiczne');

-- Dziedzina: nauki weterynaryjne (ID: 9)
-- Ta dziedzina jest jednocześnie dyscypliną
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(9, 'nauki weterynaryjne');

-- Dziedzina: sztuka (ID: 10)
INSERT INTO dyscypliny (id_dziedziny, nazwa_dyscypliny) VALUES
(10, 'sztuki filmowe i teatralne'),
(10, 'sztuki muzyczne'),
(10, 'sztuki plastyczne i konserwacja dzieł sztuki');

WITH
-- 1. Wydział Budownictwa
nowy_wydzial_1 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Budownictwa', NULL)
    RETURNING id_jednostki
),
katedry_1 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Budownictwa Lądowego', id_jednostki FROM nowy_wydzial_1
    UNION ALL
    SELECT 'Katedra Inżynierii Procesów Budowlanych', id_jednostki FROM nowy_wydzial_1
),

-- 2. Wydział Elektryczny
nowy_wydzial_2 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Elektryczny', NULL)
    RETURNING id_jednostki
),
katedry_2 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Elektroenergetyki', id_jednostki FROM nowy_wydzial_2
    UNION ALL
    SELECT 'Katedra Automatyki, Elektrotechniki i Optoelektroniki', id_jednostki FROM nowy_wydzial_2
),

-- 3. Wydział Infrastruktury i Środowiska
nowy_wydzial_3 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Infrastruktury i Środowiska', NULL)
    RETURNING id_jednostki
),
katedry_3 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Inżynierii Środowiska i Biotechnologii', id_jednostki FROM nowy_wydzial_3
    UNION ALL
    SELECT 'Katedra Zaawansowanych Technologii Energetycznych', id_jednostki FROM nowy_wydzial_3
    UNION ALL
    SELECT 'Katedra Sieci i Instalacji Sanitarnych', id_jednostki FROM nowy_wydzial_3
),

-- 4. Wydział Inżynierii Mechanicznej
nowy_wydzial_4 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Inżynierii Mechanicznej', NULL)
    RETURNING id_jednostki
),
katedry_4 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Maszyn Cieplnych', id_jednostki FROM nowy_wydzial_4
    UNION ALL
    SELECT 'Katedra Mechaniki i Podstaw Konstrukcji Maszyn', id_jednostki FROM nowy_wydzial_4
    UNION ALL
    SELECT 'Katedra Technologii i Automatyzacji', id_jednostki FROM nowy_wydzial_4
),

-- 5. Wydział Informatyki i Sztucznej Inteligencji
nowy_wydzial_5 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Informatyki i Sztucznej Inteligencji', NULL)
    RETURNING id_jednostki
),
katedry_5 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Sztucznej Inteligencji', id_jednostki FROM nowy_wydzial_5
    UNION ALL
    SELECT 'Katedra Informatyki', id_jednostki FROM nowy_wydzial_5
    UNION ALL
    SELECT 'Katedra Matematyki', id_jednostki FROM nowy_wydzial_5
),

-- 6. Wydział Inżynierii Produkcji i Technologii Materiałów
nowy_wydzial_6 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Inżynierii Produkcji i Technologii Materiałów', NULL)
    RETURNING id_jednostki
),
katedry_6 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Inżynierii Materiałowej', id_jednostki FROM nowy_wydzial_6
    UNION ALL
    SELECT 'Katedra Fizyki', id_jednostki FROM nowy_wydzial_6
    UNION ALL
    SELECT 'Katedra Metalurgii i Technologii Metali', id_jednostki FROM nowy_wydzial_6
    UNION ALL
    SELECT 'Katedra Zarządzania Produkcją', id_jednostki FROM nowy_wydzial_6
),

-- 7. Wydział Zarządzania
nowy_wydzial_7 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    VALUES ('Wydział Zarządzania', NULL)
    RETURNING id_jednostki
),
katedry_7 AS (
    INSERT INTO jednostki_organizacyjne (nazwa_jednostki, id_jednostki_nadrzednej)
    SELECT 'Katedra Logistyki', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Inżynierii Produkcji i Bezpieczeństwa', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Finansów, Bankowości i Rachunkowości', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Ekonometrii i Statystyki', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Ekonomii, Inwestycji i Nieruchomości', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Socjologii Stosowanej i Zarządzania Zasobami Ludzkimi', id_jednostki FROM nowy_wydzial_7
    UNION ALL
    SELECT 'Katedra Informacyjnych Systemów Zarządzania', id_jednostki FROM nowy_wydzial_7
)

SELECT 'Struktura uczelni została pomyślnie wgrana.' AS status;

INSERT INTO konfiguracja_aktywnosci (id_okresu, id_typu, punkty_domyslne, punkty_min, punkty_max, lp, kolejnosc) VALUES
(1, 1, NULL, NULL, 20.00, '1.', 1),
(1, 2, NULL, NULL, 20.00, '2.', 2),
(1, 3, NULL, NULL, NULL, '3.', 3),
(1, 4, NULL, NULL, NULL, '4.', 4),
(1, 5, NULL, NULL, NULL, '5.', 5),
(1, 6, NULL, NULL, NULL, '6.', 6),
(1, 7, NULL, NULL, NULL, '7.', 7),
(1, 8, NULL, NULL, NULL, '8.', 8),
(1, 9, NULL, NULL, NULL, '9.', 9),
(1, 10, NULL, NULL, NULL, '10a.', 10),
(1, 11, NULL, NULL, NULL, '10b.', 11),
(1, 12, NULL, NULL, NULL, '10c.', 12),
(1, 13, NULL, NULL, NULL, '10d.', 13),
(1, 14, NULL, NULL, NULL, '10e.', 14),
(1, 15, NULL, NULL, NULL, '11a.', 15),
(1, 16, NULL, NULL, NULL, '11b.', 16),
(1, 17, NULL, NULL, NULL, '11c.', 17),
(1, 18, NULL, NULL, NULL, '11d.', 18),
(1, 19, NULL, NULL, NULL, '11e.', 19),
(1, 20, NULL, NULL, NULL, '12.', 20),
(1, 21, NULL, NULL, NULL, '13.', 21),
(1, 22, 60.00, 60.00, 60.00, '14a.', 22),
(1, 23, 40.00, 40.00, 40.00, '14b.', 23),
(1, 24, 20.00, 20.00, 20.00, '14c.', 24),
(1, 25, 5.00, 5.00, 5.00, '14d.', 25),
(1, 26, 2.00, NULL, 2.00, '15a.', 26),
(1, 27, 4.00, NULL, 4.00, '15b.', 27),
(1, 28, 40.00, NULL, 40.00, '16.', 28),
(1, 29, 10.00, NULL, 10.00, '17.', 29),
(1, 30, 10.00, NULL, 10.00, '18.', 30),
(1, 31, NULL, 0.00, 10.00, '19.', 31),
(1, 32, NULL, 0.00, 10.00, '20.', 32),
(1, 33, 10.00, 10.00, NULL, '21.', 33),
(1, 34, 12.00, 12.00, 12.00, '22.', 34),
(1, 35, 12.00, 12.00, 12.00, '23.', 35),
(1, 36, 8.00, 8.00, 8.00, '24.', 36),
(1, 37, 8.00, 8.00, 8.00, '25.', 37),
(1, 38, 5.00, 5.00, 5.00, '26.', 38),
(1, 39, 6.00, 6.00, 6.00, '27a.', 39),
(1, 40, 4.00, 4.00, 4.00, '27b.', 40),
(1, 41, 3.00, 3.00, 3.00, '28a.', 41),
(1, 42, 2.00, 2.00, 2.00, '28b.', 42),
(1, 43, 3.00, 3.00, 3.00, '29a.', 43),
(1, 44, 2.00, 2.00, 2.00, '29b.', 44),
(1, 45, 1.00, 1.00, 1.00, '29c.', 45),
(1, 46, 5.00, NULL, 5.00, '30.', 46),
(1, 47, 10.00, NULL, 10.00, '31.', 47),
(1, 48, NULL, NULL, 25.00, '32.', 48),
(1, 49, 3.00, 3.00, 3.00, '33.', 49),
(1, 50, 5.00, 5.00, 5.00, '34.', 50),
(1, 51, 10.00, 10.00, 10.00, '35.', 51),
(1, 52, NULL, NULL, 10.00, '36.', 52),
(1, 53, 2.00, 2.00, 2.00, '37.', 53),
(1, 54, 35.00, 35.00, 35.00, '38a.', 54),
(1, 55, 25.00, 25.00, 25.00, '38b.', 55),
(1, 56, 20.00, 20.00, 20.00, '38c.', 56),
(1, 57, 15.00, 15.00, 15.00, '38d.', 57),
(1, 58, 10.00, 10.00, 10.00, '38e.', 58),
(1, 59, 12.00, 12.00, 12.00, '39a.', 59),
(1, 60, 6.00, 6.00, 6.00, '39b.', 60),
(1, 61, 8.00, 8.00, 8.00, '40.', 61),
(1, 62, 8.00, 8.00, 8.00, '41a.', 62),
(1, 63, 6.00, 6.00, 6.00, '41b.', 63),
(1, 64, 4.00, 4.00, 4.00, '41c.', 64),
(1, 65, 20.00, 20.00, 20.00, '42a.', 65),
(1, 66, 15.00, 15.00, 15.00, '42b.', 66),
(1, 67, NULL, NULL, 10.00, '42c.', 67),
(1, 68, 15.00, 15.00, 15.00, '43a.', 68),
(1, 69, 10.00, 10.00, 10.00, '43b.', 69),
(1, 70, 3.00, 3.00, 3.00, '43c.', 70),
(1, 71, 8.00, 8.00, 8.00, '44a.', 71),
(1, 72, 4.00, 4.00, 4.00, '44b.', 72),
(1, 73, 2.00, 2.00, 2.00, '44c.', 73),
(1, 74, 8.00, 8.00, 8.00, '45a.', 74),
(1, 75, 4.00, 4.00, 4.00, '45b.', 75),
(1, 76, 2.00, 2.00, 2.00, '45c.', 76),
(1, 77, 20.00, 20.00, 20.00, '46a.', 77),
(1, 78, 10.00, 10.00, 10.00, '46b.', 78),
(1, 79, 5.00, 5.00, 5.00, '46c.', 79),
(1, 80, 15.00, 15.00, 15.00, '47a.', 80),
(1, 81, 10.00, 10.00, 10.00, '47b.', 81),
(1, 82, 5.00, 5.00, 5.00, '47c.', 82),
(1, 83, 3.00, 3.00, 3.00, '47d.', 83),
(1, 84, 10.00, 10.00, 10.00, '48a.', 84),
(1, 85, 5.00, 5.00, 5.00, '48b.', 85),
(1, 86, 3.00, 3.00, 3.00, '48c.', 86),
(1, 87, 5.00, NULL, 5.00, '49a.', 87),
(1, 88, 3.00, NULL, 3.00, '49b.', 88),
(1, 89, 3.00, 3.00, 3.00, '50.', 89),
(1, 90, 4.00, 4.00, 4.00, '51.', 90),
(1, 91, 10.00, NULL, 10.00, '52a.', 91),
(1, 92, 5.00, NULL, 5.00, '52b.', 92),
(1, 93, 15.00, 15.00, 15.00, '53a.', 93),
(1, 94, 10.00, 10.00, 10.00, '53b.', 94),
(1, 95, 6.00, 6.00, 9.00, '54a.', 95),
(1, 96, 3.00, 3.00, 6.00, '54b.', 96),
(1, 97, 10.00, 10.00, 10.00, '55a.', 97),
(1, 98, 5.00, 5.00, 5.00, '55b.', 98),
(1, 99, 4.00, 4.00, 7.00, '56.', 99),
(1, 100, 4.00, 4.00, 4.00, '57a.', 100),
(1, 101, 2.00, 2.00, 2.00, '57b.', 101),
(1, 102, 25.00, 25.00, 25.00, '58a.', 102),
(1, 103, 15.00, 15.00, 15.00, '58b.', 103),
(1, 104, 4.00, 4.00, 4.00, '58c.', 104),
(1, 105, 2.00, 2.00, 2.00, '58d.', 105),
(1, 106, 20.00, 20.00, 20.00, '59a.', 106),
(1, 107, 5.00, 5.00, 5.00, '59b.', 107),
(1, 108, 3.00, 3.00, 3.00, '60a.', 108),
(1, 109, 1.00, 1.00, 1.00, '60b.', 109),
(1, 110, 10.00, 10.00, 10.00, '61a.', 110),
(1, 111, 5.00, 5.00, 5.00, '61b.', 111),
(1, 112, 3.00, 3.00, 3.00, '62.', 112),
(1, 113, 2.00, 2.00, 2.00, '63.', 113),
(1, 114, 10.00, 10.00, 10.00, '64.', 114),
(1, 115, NULL, NULL, 10.00, '65.', 115),
(1, 116, NULL, NULL, 6.00, '66.', 116);

INSERT INTO pracownicy (
    imie, 
    nazwisko, 
    orcid, 
    data_zatrudnienia, 
    czy_aktywny, 
    id_jednostki, 
    id_stopnia, 
    id_stanowiska, 
    id_grupy_stanowisk, 
    id_etatu
) VALUES 

-- 1. Jan Kowalski: Typowy Adiunkt (Badawczo-Dydaktyczny) w Katedrze Informatyki
(
    'Jan', 
    'Kowalski', 
    '0000-0001-0001-0001',
    '2015-10-01', 
    TRUE,
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki' LIMIT 1),
    (SELECT id_stopnia FROM stopnie_tytuly WHERE nazwa_stopnia = 'doktor inżynier' LIMIT 1),
    (SELECT id_stanowiska FROM stanowiska WHERE nazwa_stanowiska = 'Adiunkt' LIMIT 1),
    (SELECT id_grupy_stanowisk FROM grupy_stanowisk WHERE nazwa_grupy = 'Badawczo-dydaktyczny' LIMIT 1),
    (SELECT id_etatu FROM wymiar_etatu WHERE wartosc_liczbowa = 1.00 LIMIT 1)
),

-- 2. Anna Nowak: Młody Asystent (Badawczo-Dydaktyczny) w Katedrze Sztucznej Inteligencji
(
    'Anna', 
    'Nowak', 
    '0000-0002-0002-0002', 
    '2023-02-15', 
    TRUE,
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji' LIMIT 1),
    (SELECT id_stopnia FROM stopnie_tytuly WHERE nazwa_stopnia = 'doktor inżynier' LIMIT 1),
    (SELECT id_stanowiska FROM stanowiska WHERE nazwa_stanowiska = 'Adiunkt' LIMIT 1),
    -- Uwaga: Asystent ma zniżkę punktową (-25%), co system uwzględni w raportach
    (SELECT id_grupy_stanowisk FROM grupy_stanowisk WHERE nazwa_grupy = 'Dydaktyczny' LIMIT 1),
    (SELECT id_etatu FROM wymiar_etatu WHERE wartosc_liczbowa = 0.75 LIMIT 1)
),

-- 3. Piotr Wiśniewski: Doświadczony Profesor Uczelni (Dydaktyczny) w Katedrze Logistyki
(
    'Piotr', 
    'Wiśniewski', 
    '0000-0003-0003-0003', 
    '2005-09-01', 
    TRUE,
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki' LIMIT 1),
    (SELECT id_stopnia FROM stopnie_tytuly WHERE nazwa_stopnia = 'doktor habilitowany inżynier' LIMIT 1),
    (SELECT id_stanowiska FROM stanowiska WHERE nazwa_stanowiska = 'Profesor Uczelni' LIMIT 1),
    -- Grupa dydaktyczna (ma inne progi punktowe, nie musi publikować)
    (SELECT id_grupy_stanowisk FROM grupy_stanowisk WHERE nazwa_grupy = 'Badawczo-dydaktyczny' LIMIT 1),
    (SELECT id_etatu FROM wymiar_etatu WHERE wartosc_liczbowa = 1.00 LIMIT 1)
);

INSERT INTO pcz_oceny.filtr_uzytkownika (nazwa_uzytkownika) VALUES (current_user);
