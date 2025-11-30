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

INSERT INTO sl_typy_aktywnosci (id_grupy, lp, nazwa_parametru, punkty_domyslne, punkty_min, punkty_max) VALUES
-- Grupa 1: Działalność publikacyjna (Lp. 1-5) [cite: 181, 184]
(1, '1.', 'Publikacja w czasopiśmie naukowym wymienionym w wykazie właściwego ministra', NULL, NULL, NULL),
(1, '2.', 'Publikacja w recenzowanych materiałach z konferencji międzynarodowej wymienionej w wykazie właściwego ministra', NULL, NULL, NULL),
(1, '3.', 'Monografia naukowa wydana przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL),
(1, '4.', 'Rozdział w monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL),
(1, '5.', 'Redakcja monografii naukowej wydanej przez wydawnictwa wymienione w wykazie właściwego ministra', NULL, NULL, NULL),

-- Grupa 2: Działalność B+R (Lp. 6-15) [cite: 189-203]
(2, '6.', 'Przyznany PCz patent europejski albo patent przyznany za granicą co najmniej w jednym z państw należących do Organizacji Współpracy Gospodarczej i Rozwoju, pod warunkiem, że wynalazek został zgłoszony również w Urzędzie Patentowym Rzeczypospolitej Polskiej', NULL, NULL, NULL),
(2, '7.', 'Patent przyznany PCz przez Urząd Patentowy Rzeczypospolitej Polskiej', NULL, NULL, NULL),
(2, '8.', 'Patent przyznany innemu podmiotowi niż PCz, jeżeli autorem albo współautorem wynalazku, na który patent został przyznany jest pracownik PCz', NULL, NULL, NULL),
(2, '9.', 'Prawa ochronne na wzór użytkowy przyznane PCz przez Urząd Patentowy Rzeczypospolitej Polskiej albo za granicą', NULL, NULL, NULL),
(2, '10.', 'Uzyskane projekty obejmujące badania naukowe lub prace rozwojowe, finansowane w trybie konkursowym przez instytucje zagraniczne lub organizacje międzynarodowe lub ze środków finansowych na szkolnictwo wyższe i naukę przeznaczanych na: | a) zadania finansowane z udziałem środków pochodzących z budżetu Unii Europejskiej albo z niepodlegających zwrotowi środków z pomocy udzielanej przez państwa członkowskie Europejskiego Porozumienia o Wolnym Handlu (EFTA), albo z innych środków pochodzących ze źródeł zagranicznych niepodlegających zwrotowi; | b) zadania finansowane przez NCBIR, w tym badania naukowe i prace rozwojowe na rzecz obronności i bezpieczeństwa państwa; | c) zadania finansowane przez NCN; | d) zadania finansowane przez Fundację na Rzecz Nauki Polskiej; | e) zadania finansowane przez Narodową Agencję Wymiany Akademickiej. | (Sumy środków finansowych przyznanych... samodzielnie przez PCz lub PCz jest liderem)', NULL, NULL, NULL),
(2, '11.', 'Uzyskane projekty obejmujące badania naukowe lub prace rozwojowe, finansowane w trybie konkursowym przez instytucje zagraniczne lub organizacje międzynarodowe lub ze środków finansowych na szkolnictwo wyższe i naukę przeznaczanych na: | a) zadania finansowane z udziałem środków pochodzących z budżetu Unii Europejskiej... [itd.] | b) zadania finansowane przez NCBIR... [itd.] | c) zadania finansowane przez NCN, | d) zadania finansowane przez Fundację na Rzecz Nauki Polskiej, | e) zadania finansowane przez Narodową Agencję Wymiany Akademickiej. | (Sumy środków finansowych... w przypadku projektów realizowanych przez grupę podmiotów, do której należy PCz, której liderem jest ... podmiot nienależący do systemu...)', NULL, NULL, NULL),
(2, '12.', 'Komercjalizacja wyników badań naukowych lub prac rozwojowych lub know-how związanego z tymi wynikami albo usług badawczych świadczonych na zlecenie podmiotów nienależących do systemu szkolnictwa wyższego i nauki.', NULL, NULL, NULL),
(2, '13.', 'Realizacja projektów oraz badań zleconych i usługowych w okresie oceny', NULL, NULL, NULL),
(2, '14.', 'Uzyskane i potwierdzone przez podmioty przychody ze sprzedaży produktów będących efektem wdrożenia wyników badań naukowych lub prac rozwojowych, zrealizowanych w PCz: | 1) łączne przychody o wartości powyżej 5 mln zł - 60 pkt; | 2) łączne przychody o wartości powyżej 2,5 mln zł do 5 mln zł - 40 pkt; | 3) łączne przychody o wartości powyżej 0,5 mln zł do 2,5 mln zł - 20 pkt | 4) łączne przychody o wartości od 25 tys.zł do 0,5 mln zł - 5 pkt.', NULL, 5, 60),
(2, '15.', 'Udział w zespołach badawczych/udział w zespołach badawczych interdyscyplinarnych (za każdy udział)', NULL, 2, 4),

-- Grupa 3: Działalność dydaktyczna (Lp. 16-37) [cite: 205-213]
(3, '16.', 'Autorstwo podręcznika akademickiego/skryptu', 40, 40, 40),
(3, '17.', 'Autorstwo rozdziału w podręczniku akademickim/ w skrypcie', 10, 10, 10),
(3, '18.', 'Redakcja wieloautorskiego podręcznika akademickiego/skryptu', 10, 10, 10),
(3, '19.', 'Ocena na podstawie ankiet studentów i doktorantów (w ocenianym roku kalendarzowym)', NULL, 0, 10),
(3, '20.', 'Ocena z hospitacji zajęć dydaktycznych (w ocenianym roku kalendarzowym)', NULL, 0, 10),
(3, '21.', 'Liczba godzin w pensum dydaktycznym (nie mniej niż 10 dla pracownika prowadzącego zajęcia dydaktyczne)', NULL, 10, NULL),
(3, '22.', 'Funkcja promotora rozprawy doktorskiej, za każde promotorstwo rocznie. Nie dłużej niż 4 lata od momentu wszczęcia przewodu doktorskiego lub rozpoczęcia kształcenia w szkole doktorskiej', 12, 12, 12),
(3, '23.', 'Funkcja promotora rozprawy doktorskiej w postępowaniu zakończonym nadaniem stopnia. Jednorazowo, w roku nadania stopnia naukowego doktora', 12, 12, 12),
(3, '24.', 'Funkcja promotora pomocniczego rozprawy doktorskiej rocznie. Nie dłużej niż 4 lata od momentu wszczęcia przewodu doktorskiego lub rozpoczęcia kształcenia w szkole doktorskiej', 8, 8, 8),
(3, '25.', 'Funkcja promotora pomocniczego rozprawy doktorskiej w postępowaniu zakończonym nadaniem stopnia. Jednorazowo, w roku nadania stopnia naukowego doktora', 8, 8, 8),
(3, '26.', 'Udział w komisji egzaminacyjnej w przewodzie doktorskim w charakterze egzaminatora lub specjalisty w zakresie języka obcego...', 5, 5, 5),
(3, '27.', 'Funkcja promotora pracy inżynierskiej, licencjackiej/ magisterskiej. Maksymalnie 24 pkt rocznie', NULL, 4, 6),
(3, '28.', 'Opracowanie recenzji pracy dyplomowej (licencjackiej, inżynierskiej/magisterskiej). Maksymalnie 12 pkt rocznie', NULL, 2, 3),
(3, '29.', 'Koordynator uczelniany/koordynator wydziałowy lub koordynator zadania/członek zespołu w projekcie dydaktycznym lub inwestycyjnym finansowanym ze środków zewnętrznych', NULL, 1, 3),
(3, '30.', 'Autorstwo programu nowego przedmiotu, na studiach pierwszego, drugiego stopnia oraz w szkole doktorskiej. Wprowadzone do oferty kształcenia', 5, 5, 5),
(3, '31.', 'Przygotowanie i uruchomienie nowego laboratorium lub jego istotna, udokumentowana modyfikacja. Wprowadzone do oferty kształcenia', 10, 10, 10),
(3, '32.', 'Opracowanie nowego kierunku studiów, nowego zakresu wraz z programem kształcenia lub ich istotna modyfikacja', NULL, NULL, 25),
(3, '33.', 'Opieka nad działającym kołem naukowym', 3, 3, 3),
(3, '34.', 'Podniesienie kwalifikacji zawodowych (potwierdzone każdorazowo certyfikatem): doskonalenie warsztatu poprzez udział w szkoleniach, kursach, konferencjach', 5, 5, 5),
(3, '35.', 'Prowadzenie kursów i szkoleń prowadzących do podniesienia kwalifikacji zawodowych (potwierdzone każdorazowo certyfikatem)...', 10, 10, 10),
(3, '36.', 'Opieka nad laboratorium', NULL, NULL, 10),
(3, '37.', 'Udział w międzynarodowych programach wymiany akademickiej', 2, 2, 2),

-- Grupa 4: Działalność organizacyjna (Lp. 38-66) [cite: 213-223]
(4, '38.', 'Pełnienie funkcji prorektora/dziekana/kierownika szkoły doktorskiej, prodziekana ds. nauki, prodziekana ds. dydaktycznych, prodziekana ds. rozwoju, kierownika jednostki międzywydziałowej/zastępcy: prodziekana ds. dydaktycznych, kierownika jednostki międzywydziałowej, kierownika katedry/zastępcy kierownika katedry', NULL, 10, 35),
(4, '39.', 'Pełnienie funkcji pełnomocnika lub koordynatora rektora/dziekana', NULL, 6, 12),
(4, '40.', 'Pełnienie funkcji kierownika studiów doktoranckich/kierownika biura studentów zagranicznych', 8, 8, 8),
(4, '41.', 'Udział z wyboru we władzach centralnych towarzystw naukowych/związków i organizacji branżowych krajowych/regionalnych', NULL, 4, 8),
(4, '42.', 'Organizacja międzynarodowej konferencji naukowej/dydaktycznej (ang. organizing committee): | 1) przewodniczący komitetu organizacyjnego; | 2) sekretarz lub zastępca przewodniczącego komitetu organizacyjnego; | 3) pozostali członkowie komitetu organizacyjnego.', NULL, NULL, 20),
(4, '43.', 'Organizacja krajowej konferencji naukowej/dydaktycznej: | 1) przewodniczący komitetu organizacyjnego lub jego odpowiednik; | 2) sekretarz lub zastępca przewodniczącego komitetu organizacyjnego; | 3) pozostali członkowie komitetu organizacyjnego.', NULL, 3, 15),
(4, '44.', 'Organizacja konferencji studenckiej: | 1) przewodniczący komitetu organizacyjnego lub jego odpowiednik; | 2) sekretarz komitetu organizacyjnego | 3) pozostali członkowie komitetu organizacyjnego', NULL, 2, 8),
(4, '45.', 'Organizacja i przeprowadzenie (poza pensum dydaktycznym) kursów studenckich, olimpiad przedmiotowych/konkursów zewnętrznych/zajęć dla szkół średnich, uczelnianych rozgrywek sportowych, uczelnianych konkursów tematycznych, wycieczek dydaktycznych', NULL, 2, 8),
(4, '46.', 'Nagroda prezydenta, premiera/ministra/marszałka województwa, wojewody, prezydenta miasta', NULL, 5, 20),
(4, '47.', 'Promotorstwo wyróżnionych lub nagrodzonych prac dyplomowych i projektowych (poziom międzynarodowy/poziom krajowy/poziom regionalny/poziom uczelniany)', NULL, 3, 15),
(4, '48.', 'Uzyskanie nagrody innej niż wymieniona powyżej, na poziomie międzynarodowym/krajowym/regionalnym', NULL, 3, 10),
(4, '49.', 'Nagrody przyznawane przez zagraniczne instytucje edukacyjne/nagrody przyznawane przez krajowe instytucje edukacyjne', NULL, 3, 5),
(4, '50.', 'Członkostwo w zespołach i komisjach powołanych zarządzeniem rektora, nie wymienionych w pozostałych pozycjach arkusza oraz komisjach senackich (bez funkcji kierowniczych/bez przewodniczących)', 3, 3, 3),
(4, '51.', 'Przewodniczenie w zespołach i komisjach powołanych zarządzeniem rektora, niewymienionych wcześniej oraz komisjach senackich', 4, 4, 4),
(4, '52.', 'Członkostwo w Uczelnianej/Wydziałowej Komisji ds. Jakości Kształcenia (bez przewodniczącego)', NULL, 5, 10),
(4, '53.', 'Przewodniczenie w Uczelnianej/Wydziałowej Komisji ds. Jakości Kształcenia', NULL, 10, 15),
(4, '54.', 'Członkostwo w komisji rekrutacyjnej: doktoranckiej/wydziałowej', NULL, 3, 6),
(4, '55.', 'Opiekun roku studenckiego/opiekun praktyk studenckich jednego roku', NULL, 5, 10),
(4, '56.', 'Członkostwo w komisjach i zespołach zadaniowych powołanych decyzją osoby pełniącej funkcję kierowniczą', 4, 4, 4),
(4, '57.', 'Członkostwo we władzach zagranicznych lub międzynarodowych/krajowych towarzystw, organizacji i instytucji naukowych', NULL, 2, 4),
(4, '58.', 'Członkostwo w PAN/członkostwo w komitecie/członek stowarzyszony z sekcją PAN, ekspert/ członkostwo w komisji', NULL, 2, 25),
(4, '59.', 'Działalność w zespołach i panelach instytucji centralnych, np. w Polskiej Komisji Akredytacyjnej, Radzie Nauki, Radzie Głównej Nauki i Szkolnictwa Wyższego/instytucjach regionalnych', NULL, 5, 20),
(4, '60.', 'Aktywny udział w międzynarodowych/krajowych targach i spotkaniach edukacyjnych (w imieniu PCz)', NULL, 1, 3),
(4, '61.', 'Redaktor czasopisma naukowego/numeru czasopisma naukowego', NULL, 5, 10),
(4, '62.', 'Wystąpienia i publikacje w mediach (telewizja, prasa, radio, Internet) w roli eksperta Uczelni lub gościa - uczestnika programu lub debaty', 3, 3, 3),
(4, '63.', 'Wykonanie tłumaczeń i korekt językowych dokumentów i umów związanych z działalnością uczelni (dotyczy SJO)', 2, 2, 2),
(4, '64.', 'Organizacja Dni Sportu i innych imprez sportowych i kulturalnych', 10, 10, 10),
(4, '65.', 'Inne szczególne działania służące promocji i budowaniu pozytywnego wizerunku Uczelni/Wydziału', NULL, NULL, 10),
(4, '66.', 'Inne prace organizacyjne nieuwzględnione powyżej', NULL, NULL, 6);

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