-- Ustawienie schematu, w którym działamy
SET search_path TO oceny_pracownikow;

INSERT INTO pracownicy (imie, nazwisko, orcid, data_zatrudnienia, id_jednostki, id_typu_stanowiska, id_stopnia)
VALUES
(
    'Adam', 'Wiśniewski', '0000-0001-0001-0001', '2019-10-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki'), 
    1, 2 -- badawczo-dydaktyczny, dr hab.
),
(
    'Ewa', 'Kowalska', '0000-0001-0002-0002', '2020-03-15', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji'), 
    1, 1 -- badawczo-dydaktyczny, dr
),
(
    'Marek', 'Kamiński', '0000-0001-0003-0003', '2018-05-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki'), 
    2, 3 -- badawczy, prof.
),
(
    'Zofia', 'Lewandowska', '0000-0001-0004-0004', '2021-11-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji'), 
    1, 1 -- badawczo-dydaktyczny, dr
),
(
    'Michał', 'Zieliński', '0000-0001-0005-0005', '2017-09-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki'), 
    1, 2 -- badawczo-dydaktyczny, dr hab.
),
(
    'Julia', 'Szymańska', '0000-0001-0006-0006', '2022-02-10', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji'), 
    1, 1 -- badawczo-dydaktyczny, dr
),
(
    'Paweł', 'Woźniak', '0000-0001-0007-0007', '2016-07-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki'), 
    1, 3 -- badawczo-dydaktyczny, prof.
),
(
    'Alicja', 'Dąbrowska', '0000-0001-0008-0008', '2023-01-15', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji'), 
    2, 2 -- badawczy, dr hab.
),
(
    'Robert', 'Kozłowski', '0000-0001-0009-0009', '2019-12-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Informatyki'), 
    1, 1 -- badawczo-dydaktyczny, dr
),
(
    'Monika', 'Jankowska', '0000-0001-0010-0010', '2020-10-01', 
    (SELECT id_jednostki FROM jednostki_organizacyjne WHERE nazwa_jednostki = 'Katedra Sztucznej Inteligencji'), 
    3, 1 -- dydaktyczny, dr
);