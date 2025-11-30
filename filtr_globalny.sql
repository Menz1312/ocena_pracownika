SET search_path TO oceny_pracownikow;

-- Tabela przechowująca tylko 1 rekord: ID aktualnie wybranego pracownika
CREATE TABLE filtr_globalny (
    id_filtra INT PRIMARY KEY DEFAULT 1, -- Stałe ID rekordu
    id_wybranego_pracownika INT REFERENCES pracownicy(id_pracownika),
    CONSTRAINT tylko_jeden_rekord CHECK (id_filtra = 1)
);

-- Wstawiamy ten jeden, jedyny rekord i ustawiamy go na pierwszego pracownika
INSERT INTO filtr_globalny (id_filtra, id_wybranego_pracownika)
VALUES (1, (SELECT MIN(id_pracownika) FROM pracownicy));