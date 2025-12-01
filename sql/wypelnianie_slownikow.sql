-- Ustawienie schematu, w którym działamy
SET search_path TO oceny_pracownikow;

-- 1. WYPEŁNIENIE SŁOWNIKA GŁÓWNYCH GRUP DZIAŁAŃ
-- Na podstawie podsumowania w Załączniku 1 [cite: 223]
INSERT INTO sl_grupy_dzialan (nazwa_grupy, kod_grupy) VALUES
('Działalność publikacyjna (art. i monografie)', 'PUB'),
('Działalność B+R', 'BR'),
('Działalność dydaktyczna', 'DYD'),
('Działalność organizacyjna i pozostałe', 'ORG');

-- 2. WYPEŁNIENIE TYPÓW STANOWISK I ICH PROGÓW PUNKTOWYCH
-- Na podstawie Zał. do Zarządzenia Nr 50/2024, § 8 ust. 3, 4 [cite: 104, 106-108]
INSERT INTO typy_stanowisk (nazwa_typu, prog_punktowy_total, prog_punktowy_pub, prog_punktowy_inny) VALUES
('badawczo-dydaktyczny', 100.00, 60.00, NULL),
('badawczy', 100.00, 80.00, NULL),
('dydaktyczny', 100.00, NULL, 80.00);

-- 3. WYPEŁNIENIE SŁOWNIKA TYPÓW AKTYWNOŚCI (WSZYSTKIE 66 POZYCJI)
-- Na podstawie Załącznika nr 1 "Arkusz oceny..." [cite: 178-223]
-- ID Grup: 1='PUB', 2='BR', 3='DYD', 4='ORG'

-- WYPEŁNIENIE SŁOWNIKA TYPÓW AKTYWNOŚCI
-- Kolumny: id_grupy, lp, nazwa_parametru, punkty_domyslne, punkty_min, punkty_max, czy_ciagla

INSERT INTO sl_typy_aktywnosci (id_grupy, lp, nazwa_parametru, punkty_domyslne, punkty_min, punkty_max, czy_ciagla) VALUES

-- === Grupa 1: Działalność publikacyjna (Lp. 1-5) ===
(1, '1.', 'Publikacja w czasopiśmie naukowym wymienionym w wykazie właściwego ministra', NULL, NULL, 20, FALSE),
(1, '2.', 'Publikacja w recenzowanych materiałach z konferencji międzynarodowej wymienionej w wykazie właściwego ministra', NULL, NULL, 20, FALSE),
(1, '3.', 'Monografia naukowa wydana przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL, FALSE),
(1, '4.', 'Rozdział w monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL, FALSE),
(1, '5.', 'Redakcja monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL, FALSE),

-- === Grupa 2: Działalność B+R (Lp. 6-15) ===
(2, '6.', 'Przyznany PCz patent europejski albo patent przyznany za granicą...', NULL, NULL, NULL, FALSE),
(2, '7.', 'Patent przyznany PCz przez Urząd Patentowy Rzeczypospolitej Polskiej', NULL, NULL, NULL, FALSE),
(2, '8.', 'Patent przyznany innemu podmiotowi niż PCz (autor pracownik PCz)', NULL, NULL, NULL, FALSE),
(2, '9.', 'Prawa ochronne na wzór użytkowy przyznane PCz...', NULL, NULL, NULL, FALSE),

-- Rozbicie punktu 10 (Projekty B+R - PCz liderem/samodzielnie)
(2, '10a.', 'Projekt B+R (PCz lider): Finansowany z budżetu UE, EFTA lub zagraniczne bezzwrotne', NULL, NULL, NULL, TRUE),
(2, '10b.', 'Projekt B+R (PCz lider): Finansowany przez NCBIR (obronność/bezpieczeństwo)', NULL, NULL, NULL, TRUE),
(2, '10c.', 'Projekt B+R (PCz lider): Finansowany przez NCN', NULL, NULL, NULL, TRUE),
(2, '10d.', 'Projekt B+R (PCz lider): Finansowany przez FNP', NULL, NULL, NULL, TRUE),
(2, '10e.', 'Projekt B+R (PCz lider): Finansowany przez NAWA', NULL, NULL, NULL, TRUE),

-- Rozbicie punktu 11 (Projekty B+R - PCz partnerem)
(2, '11a.', 'Projekt B+R (PCz partner): Finansowany z budżetu UE, EFTA lub zagraniczne bezzwrotne', NULL, NULL, NULL, TRUE),
(2, '11b.', 'Projekt B+R (PCz partner): Finansowany przez NCBIR (obronność/bezpieczeństwo)', NULL, NULL, NULL, TRUE),
(2, '11c.', 'Projekt B+R (PCz partner): Finansowany przez NCN', NULL, NULL, NULL, TRUE),
(2, '11d.', 'Projekt B+R (PCz partner): Finansowany przez FNP', NULL, NULL, NULL, TRUE),
(2, '11e.', 'Projekt B+R (PCz partner): Finansowany przez NAWA', NULL, NULL, NULL, TRUE),

(2, '12.', 'Komercjalizacja wyników badań / usługi badawcze (dla podmiotów spoza szkolnictwa)', NULL, NULL, NULL, FALSE),
(2, '13.', 'Realizacja projektów oraz badań zleconych i usługowych', NULL, NULL, NULL, TRUE),

-- Rozbicie punktu 14 (Przychody z wdrożeń)
(2, '14a.', 'Przychody z wdrożeń: powyżej 5 mln zł', 60, 60, 60, FALSE),
(2, '14b.', 'Przychody z wdrożeń: powyżej 2,5 mln zł do 5 mln zł', 40, 40, 40, FALSE),
(2, '14c.', 'Przychody z wdrożeń: powyżej 0,5 mln zł do 2,5 mln zł', 20, 20, 20, FALSE),
(2, '14d.', 'Przychody z wdrożeń: od 25 tys. zł do 0,5 mln zł', 5, 5, 5, FALSE),

(2, '15a.', 'Udział w zespołach badawczych (za każdy udział)', 2, NULL, 2, TRUE),
(2, '15b.', 'Udział w zespołach badawczych interdyscyplinarnych (za każdy udział)', 4, NULL, 4, TRUE),

-- === Grupa 3: Działalność dydaktyczna (Lp. 16-37) ===
(3, '16.', 'Autorstwo podręcznika akademickiego/skryptu', 40, NULL, 40, FALSE),
(3, '17.', 'Autorstwo rozdziału w podręczniku akademickim/skrypcie', 10, NULL, 10, FALSE),
(3, '18.', 'Redakcja wieloautorskiego podręcznika akademickiego/skryptu', 10, NULL, 10, FALSE),
(3, '19.', 'Ocena na podstawie ankiet studentów i doktorantów', NULL, 0, 10, FALSE),
(3, '20.', 'Ocena z hospitacji zajęć dydaktycznych', NULL, 0, 10, FALSE),
(3, '21.', 'Liczba godzin w pensum dydaktycznym', 10, 10, NULL, FALSE),
(3, '22.', 'Funkcja promotora rozprawy doktorskiej (rocznie)', 12, 12, 12, TRUE),
(3, '23.', 'Funkcja promotora rozprawy doktorskiej (zakończona nadaniem stopnia)', 12, 12, 12, FALSE),
(3, '24.', 'Funkcja promotora pomocniczego rozprawy doktorskiej (rocznie)', 8, 8, 8, TRUE),
(3, '25.', 'Funkcja promotora pomocniczego rozprawy doktorskiej (zakończona nadaniem stopnia)', 8, 8, 8, FALSE),
(3, '26.', 'Udział w komisji egzaminacyjnej w przewodzie doktorskim', 5, 5, 5, FALSE),

-- Rozbicie punktu 27 (Promotorstwo prac dyplomowych)
(3, '27a.', 'Promotorstwo pracy magisterskiej', 6, 6, 6, FALSE),
(3, '27b.', 'Promotorstwo pracy inżynierskiej / licencjackiej', 4, 4, 4, FALSE),

-- Rozbicie punktu 28 (Recenzje prac dyplomowych)
(3, '28a.', 'Recenzja pracy magisterskiej', 3, 3, 3, FALSE),
(3, '28b.', 'Recenzja pracy inżynierskiej / licencjackiej', 2, 2, 2, FALSE),

-- Rozbicie punktu 29 (Koordynator projektu dydaktycznego)
(3, '29a.', 'Koordynator uczelniany projektu dydaktycznego/inwestycyjnego', 3, 3, 3, TRUE),
(3, '29b.', 'Koordynator wydziałowy projektu dydaktycznego/inwestycyjnego', 2, 2, 2, TRUE),
(3, '29c.', 'Koordynator zadania / członek zespołu w projekcie dydaktycznym', 1, 1, 1, TRUE),

(3, '30.', 'Autorstwo programu nowego przedmiotu', 5, NULL, 5, FALSE),
(3, '31.', 'Przygotowanie i uruchomienie nowego laboratorium', 10, NULL, 10, FALSE),
(3, '32.', 'Opracowanie nowego kierunku studiów', NULL, NULL, 25, FALSE),
(3, '33.', 'Opieka nad działającym kołem naukowym', 3, 3, 3, TRUE),
(3, '34.', 'Podniesienie kwalifikacji zawodowych (udział w szkoleniu/kursie)', 5, 5, 5, FALSE),
(3, '35.', 'Prowadzenie kursów i szkoleń podnoszących kwalifikacje', 10, 10, 10, FALSE),
(3, '36.', 'Opieka nad laboratorium', NULL, NULL, 10, TRUE),
(3, '37.', 'Udział w międzynarodowych programach wymiany akademickiej', 2, 2, 2, FALSE),

-- === Grupa 4: Działalność organizacyjna (Lp. 38-66) ===

-- Rozbicie punktu 38 (Funkcje kierownicze główne)
(4, '38a.', 'Funkcja prorektora', 35, 35, 35, TRUE),
(4, '38b.', 'Funkcja dziekana', 25, 25, 25, TRUE),
(4, '38c.', 'Funkcja kierownika szkoły doktorskiej, prodziekana ds. dydaktycznych, prodziekana ds. rozwoju, kierownika jednostki wydziałowej', 20, 20, 20, TRUE),
(4, '38d.', 'Funkcja zastępcy: prodziekana ds. dydaktycznych, kierownika jednostki międzywydziałowej, kierownika katedry', 15, 15, 15, TRUE),
(4, '38e.', 'Funkcja zastępcy kierownika katedry', 10, 10, 10, TRUE),

-- Rozbicie punktu 39 (Pełnomocnicy)
(4, '39a.', 'Pełnienie funkcji pełnomocnika lub koordynatora rektora', 12, 12, 12, TRUE),
(4, '39b.', 'Pełnienie funkcji pełnomocnika lub koordynatora dziekana', 6, 6, 6, TRUE),

(4, '40.', 'Pełnienie funkcji kierownika studiów doktoranckich lub kierownika biura studentów zagranicznych', 8, 8, 8, TRUE),

-- Rozbicie punktu 41 (Władze towarzystw)
(4, '41a.', 'Udział z wyboru we władzach centralnych towarzystw naukowych', 8, 8, 8, TRUE),
(4, '41b.', 'Udział z wyboru we władzach centralnych związków i organizacji branżowych krajowych', 6, 6, 6, TRUE),
(4, '41c.', 'Udział z wyboru we władzach centralnych związków i organizacji branżowych regionalnych', 4, 4, 4, TRUE),

-- Rozbicie punktu 42 (Konferencja MIĘDZYNARODOWA)
(4, '42a.', 'Organizacja międzynarodowej konferencji naukowej/dydaktycznej: przewodniczący komitetu', 20, 20, 20, FALSE),
(4, '42b.', 'Organizacja międzynarodowej konferencji naukowej/dydaktycznej: sekretarz lub zastępca przewodniczącego', 15, 15, 15, FALSE),
(4, '42c.', 'Organizacja międzynarodowej konferencji naukowej/dydaktycznej: członek komitetu', NULL, NULL, 10, FALSE),

-- Rozbicie punktu 43 (Konferencja KRAJOWA)
(4, '43a.', 'Organizacja krajowej konferencji naukowej/dydaktycznej: przewodniczący komitetu', 15, 15, 15, FALSE),
(4, '43b.', 'Organizacja krajowej konferencji naukowej/dydaktycznej: sekretarz lub zastępca przewodniczącego', 10, 10, 10, FALSE),
(4, '43c.', 'Organizacja krajowej konferencji naukowej/dydaktycznej: członek komitetu', 3, 3, 3, FALSE),

-- Rozbicie punktu 44 (Konferencja STUDENCKA)
(4, '44a.', 'Organizacja konferencji studenckiej: przewodniczący komitetu', 8, 8, 8, FALSE),
(4, '44b.', 'Organizacja konferencji studenckiej: sekretarz komitetu', 4, 4, 4, FALSE),
(4, '44c.', 'Organizacja konferencji studenckiej: członek komitetu', 2, 2, 2, FALSE),

-- Rozbicie punktu 45 (Kursy studenckie, olimpiady - poza pensum)
(4, '45a.', 'Organizacja i przeprowadzenie kursów studenckich, olimpiad przedmiotowych', 8, 8, 8, FALSE),
(4, '45b.', 'Organizacja i przeprowadzenie konkursów zewnętrznych', 4, 4, 4, FALSE),
(4, '45c.', 'Organizacja i przeprowadzenie zajęć dla szkół średnich, uczelnianych rozgrywek sportowych, uczelnianych konkursów tematycznych, wycieczek dydaktycznych', 2, 2, 2, FALSE),

-- Rozbicie punktu 46 (Nagrody Państwowe)
(4, '46a.', 'Nagroda prezydenta, premiera', 20, 20, 20, FALSE),
(4, '46b.', 'Nagroda ministra', 10, 10, 10, FALSE),
(4, '46c.', 'Nagroda marszałka województwa, wojewody, prezydenta miasta', 5, 5, 5, FALSE),

-- Rozbicie punktu 47 (Promotorstwo nagrodzonych prac)
(4, '47a.', 'Promotorstwo wyróżnionych lub nagrodzonych prac: poziom międzynarodowy', 15, 15, 15, FALSE),
(4, '47b.', 'Promotorstwo wyróżnionych lub nagrodzonych prac: poziom krajowy', 10, 10, 10, FALSE),
(4, '47c.', 'Promotorstwo wyróżnionych lub nagrodzonych prac: poziom regionalny', 5, 5, 5, FALSE),
(4, '47d.', 'Promotorstwo wyróżnionych lub nagrodzonych prac: poziom uczelniany', 3, 3, 3, FALSE),

-- Rozbicie punktu 48 (Inne nagrody własne)
(4, '48a.', 'Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie międzynarodowym', 10, 10, 10, FALSE),
(4, '48b.', 'Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie krajowym', 5, 5, 5, FALSE),
(4, '48c.', 'Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie regionalnym', 3, 3, 3, FALSE),

-- Rozbicie punktu 49 (Nagrody edukacyjne)
(4, '49a.', 'Nagrody przyznawane przez zagraniczne instytucje edukacyjne', 5, NULL, 5, FALSE),
(4, '49b.', 'Nagrody przyznawane przez krajowe instytucje edukacyjne', 3, NULL, 3, FALSE),

(4, '50.', 'Członkostwo w komisjach rektorskich/senackich (bez funkcji)', 3, 3, 3, TRUE),
(4, '51.', 'Przewodniczenie w komisjach rektorskich/senackich', 4, 4, 4, TRUE),

-- Rozbicie punktu 52 (Komisja Jakości Kształcenia - członek)
(4, '52a.', 'Komisja Jakości Kształcenia (Uczelniana): Członek', 10, NULL, 10, TRUE),
(4, '52b.', 'Komisja Jakości Kształcenia (Wydziałowa): Członek', 5, NULL, 5, TRUE),

-- Rozbicie punktu 53 (Komisja Jakości Kształcenia - przew.)
(4, '53a.', 'Komisja Jakości Kształcenia (Uczelniana): Przewodniczący', 15, 15, 15, TRUE),
(4, '53b.', 'Komisja Jakości Kształcenia (Wydziałowa): Przewodniczący', 10, 10, 10, TRUE),

-- Rozbicie punktu 54 (Komisja Rekrutacyjna)
(4, '54a.', 'Komisja Rekrutacyjna: Wydziałowa', 6, 6, 9, FALSE),
(4, '54b.', 'Komisja Rekrutacyjna: Doktorancka', 3, 3, 6, FALSE),

-- Rozbicie punktu 55 (Opiekun roku)
(4, '55a.', 'Opiekun praktyk studenckich', 10, 10, 10, TRUE),
(4, '55b.', 'Opiekun roku studenckiego', 5, 5, 5, TRUE),

(4, '56.', 'Członkostwo w komisjach powołanych przez kierownika', 4, 4, 7, TRUE),

-- Rozbicie punktu 57 (Władze towarzystw - inne)
(4, '57a.', 'Władze zagraniczne/międzynarodowe towarzystw naukowych', 4, 4, 4, TRUE),
(4, '57b.', 'Władze krajowe towarzystw naukowych', 2, 2, 2, TRUE),

-- Rozbicie punktu 58 (PAN)
(4, '58a.', 'Członkostwo w PAN', 25, 25, 25, TRUE),
(4, '58b.', 'Członkostwo w komitecie PAN', 15, 15, 15, TRUE),
(4, '58c.', 'Członek stowarzyszony z sekcją PAN, ekspert', 4, 4, 4, TRUE),
(4, '58d.', 'Członek komisji PAN', 2, 2, 2, TRUE),

-- Rozbicie punktu 59 (Instytucje centralne)
(4, '59a.', 'Działalność w panelach instytucji centralnych (PKA, RDN, NCN)', 20, 20, 20, TRUE),
(4, '59b.', 'Działalność w instytucjach regionalnych', 5, 5, 5, TRUE),

-- Rozbicie punktu 60 (Targi)
(4, '60a.', 'Udział w targach: Międzynarodowych', 3, 3, 3, FALSE),
(4, '60b.', 'Udział w targach: Krajowych', 1, 1, 1, FALSE),

-- Rozbicie punktu 61 (Redaktor czasopisma)
(4, '61a.', 'Redaktor czasopisma naukowego', 10, 10, 10, TRUE),
(4, '61b.', 'Redaktor numeru czasopisma naukowego', 5, 5, 5, FALSE),

(4, '62.', 'Wystąpienia w mediach jako ekspert', 3, 3, 3, FALSE),
(4, '63.', 'Tłumaczenia / korekty językowe (SJO)', 2, 2, 2, FALSE),
(4, '64.', 'Organizacja Dni Sportu / imprez kulturalnych', 10, 10, 10, FALSE),
(4, '65.', 'Inne działania promocyjne', NULL, NULL, 10, FALSE),
(4, '66.', 'Inne prace organizacyjne', NULL, NULL, 6, FALSE);

--4. STOPNIE NAUKOWE
INSERT INTO stopnie_naukowe (nazwa_stopnia) VALUES
('doktor'),
('doktor habilitowany'),
('profesor');

-- 5. WYPEŁNIENIE SŁOWNIKA DZIEDZIN NAUKI
-- Na podstawie Rozporządzenia Ministra (Dz. U. z 2022 r. poz. 2202)
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

-- 6. WYPEŁNIENIE SŁOWNIKA DYSCYPLIN NAUKOWYCH
-- Na podstawie Rozporządzenia Ministra (Dz. U. z 2022 r. poz. 2202)

-- Dziedzina: nauki humanistyczne (ID: 1)
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

-- Ustawienie schematu, w którym działamy
SET search_path TO oceny_pracownikow;

-- Używamy "WITH" (Common Table Expressions), aby wstawiać
-- jednostki nadrzędne (Wydziały) i natychmiast używać ich ID 
-- do wstawiania jednostek podrzędnych (Katedr).

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

-- Ostatnia instrukcja SELECT jest wymagana, aby wykonać wszystkie
-- operacje zdefiniowane w blokach WITH.
SELECT 'Struktura uczelni została pomyślnie wgrana.' AS status;