CREATE TABLE Ärzt_in(
    LANR TEXT(9) PRIMARY KEY NOT NULL,
    CHECK(length(LANR)=9),
    Fachgebiet TEXT NOT NULL,
    Name STRUCT(Titel TEXT, Vorname TEXT, Nachname TEXT) NOT NULL,
    Sprachen TEXT[] NOT NULL,
    Geburtsdatum DATE NOT NULL,
    CHECK(Geburtsdatum >= '1956-05-17')
);

CREATE TABLE Diagnose(
    ICD TEXT(3) NOT NULL PRIMARY KEY,
    CHECK(ICD ~ '^[A-Z]{1}[0-9]{2}$'),
    Zusatzinformation TEXT(1) NOT NULL,
    Beschreibung TEXT,
    CHECK(Zusatzinformation in ('G', 'V', 'A', 'L', 'R', 'B'))
);
CREATE TABLE Gesundheitseinrichtung(
    SteuerID TEXT(11) NOT NULL,
    CHECK(length(SteuerID)=11),
    CHECK (SteuerID ~ '^DE[0-9]{9}$'),
    Name TEXT NOT NULL,
    Adresse TEXT NOT NULL,
    Bundesland TEXT(5) NOT NULL,
    CHECK(Bundesland IN ('DE-BW', 'DE-BY', 'DE-BE', 'DE-BB', 'DE-HB', 'DE-HH', 'DE-HE', 'DE-MV', 'DE-NI', 'DE-NW', 'DE-RP', 'DE-SL', 'DE-SN', 'DE-ST', 'DE-SH', 'DE-TH')),
    Umsatz Decimal(15,2) NOT NULL,
    CHECK(Umsatz >= 0 AND Umsatz <= 9999999999999.99),
    PRIMARY KEY(SteuerID, Name),
    Typ TEXT NOT NULL,
    Fachrichtung TEXT,
    Zahlungsart TEXT,
    Betten USMALLINT,
    Bettenauslastung REAL,
    CHECK(Bettenauslastung >= 0 AND Bettenauslastung <= 1),
    ist_privatisiert BOOLEAN,
    ist_Universitätsklinikum BOOLEAN,
    CHECK (
    (Typ = 'Krankenhaus' 
        AND Betten IS NOT NULL 
        AND Bettenauslastung IS NOT NULL 
        AND ist_privatisiert IS NOT NULL 
        AND ist_Universitätsklinikum IS NOT NULL 
        AND Fachrichtung IS NULL 
        AND Zahlungsart IS NULL 
        AND Betten <= 1500) 
    OR
    (Typ = 'Privatpraxis' 
        AND Betten IS NULL 
        AND Bettenauslastung IS NULL 
        AND ist_privatisiert IS NULL 
        AND ist_Universitätsklinikum IS NULL 
        AND Fachrichtung IS NOT NULL 
        AND Zahlungsart IS NOT NULL 
        AND Zahlungsart IN ('Versichert', 'Selbstzahler')) 
    OR
    (Typ NOT IN ('Krankenhaus', 'Privatpraxis') 
        AND Betten IS NULL 
        AND Bettenauslastung IS NULL 
        AND ist_privatisiert IS NULL 
        AND ist_Universitätsklinikum IS NULL 
        AND Fachrichtung IS NULL 
        AND Zahlungsart IS NULL)
    )
);

CREATE TABLE angestellt(
    Einstellungsdatum DATE NOT NULL,
    Gehalt DECIMAL(7,2) NOT NULL,
    CHECK (Gehalt >= 5288.32 AND Gehalt <= 11019.20),
    CHECK(
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 1 AND EXTRACT(DAY FROM Einstellungsdatum ) = 1) AND
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 3 AND EXTRACT(DAY FROM Einstellungsdatum ) = 8) AND
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 5 AND EXTRACT(DAY FROM Einstellungsdatum ) = 1) AND
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 10 AND EXTRACT(DAY FROM Einstellungsdatum ) = 3) AND
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 12 AND EXTRACT(DAY FROM Einstellungsdatum ) = 25) AND
        NOT (EXTRACT(MONTH FROM Einstellungsdatum ) = 12 AND EXTRACT(DAY FROM Einstellungsdatum ) = 26)
    ),
    LANR TEXT(9) NOT NULL,
    SteuerID TEXT(11) NOT NULL,
    Name TEXT NOT NULL,
    PRIMARY KEY (LANR, SteuerID, Name),
    FOREIGN KEY (LANR) REFERENCES Ärzt_in(LANR),
    FOREIGN KEY (SteuerID, Name) REFERENCES Gesundheitseinrichtung(SteuerID, Name)
);

CREATE TABLE Patient_in(
    Versichertennummer TEXT(10) PRIMARY KEY NOT NULL,
    CHECK(Versichertennummer ~ '^[A-Z]{1}[0-9]{9}$'),
    Name STRUCT(Titel TEXT, Vorname TEXT, Nachname TEXT) NOT NULL,
    Geburtsdatum DATE NOT NULL,
    Beschäftigung TEXT,
    Geschlecht TEXT(1),
    CHECK(Geschlecht in ('m', 'w', 'd'))
);

CREATE TABLE stellt(
    LANR TEXT(9) NOT NULL,
    ICD TEXT(3) NOT NULL,
    Zeitpunkt TIMESTAMP NOT NULL,
    PRIMARY KEY(LANR, ICD),
    FOREIGN KEY(LANR) REFERENCES Ärzt_in(LANR),
    FOREIGN KEY(ICD) REFERENCES Diagnose(ICD),
    UNIQUE (LANR, Zeitpunkt)
);

CREATE SEQUENCE termin_id_seq START WITH 1 INCREMENT BY 1 MAXVALUE 3000000;
CREATE TABLE Termin (
    --ID INTEGER PRIMARY KEY NOT NULL,
    ID UINTEGER DEFAULT NEXTVAL('termin_id_seq') PRIMARY KEY,
    CHECK(ID>0),
    LANR CHAR(9) NOT NULL,
    Zeitpunkt TIMESTAMP NOT NULL,
    Zusatzgebühren DECIMAL(5,2) DEFAULT 0 NOT NULL,
    CHECK(Zusatzgebühren >= 0 AND Zusatzgebühren <= 500),
    FOREIGN KEY(LANR) REFERENCES Ärzt_in(LANR),
    ist_Neupatient_in BOOLEAN NOT NULL,
    UNIQUE(LANR, Zeitpunkt)
);

/*
CREATE TABLE OP(
    Nummer UUID PRIMARY KEY NOT NULL,
    Dringlichkeit TEXT NOT NULL,
    CHECK (Dringlichkeit IN ('Notoperation', 'dringliche Operation', 'frühelektive Operation')),
    ist_Vollnarkose BOOLEAN NOT NULL,
    Datum DATE NOT NULL,
    Startzeit TIMESTAMP NOT NULL,
    Endzeit TIMESTAMP NOT NULL
);*/


--CREATE SEQUENCE raumnr_seq START WITH 1 INCREMENT BY 1 MAXVALUE 3000000;
CREATE TABLE "OP-Saal" (
    Raumnummer UTINYINT NOT NULL ,
    CHECK(Raumnummer >=0 AND Raumnummer <= 20),
    SteuerID VARCHAR(11) NOT NULL,
    Name VARCHAR,
    PRIMARY KEY (Raumnummer,SteuerID,Name),
    FOREIGN KEY (SteuerID,Name) REFERENCES Gesundheitseinrichtung (SteuerID, Name)
);

CREATE TABLE OP (
    Nummer UUID NOT NULL PRIMARY KEY,
    Dringlichkeit VARCHAR(128) NOT NULL CHECK (Dringlichkeit IN ('Notoperation', 'dringliche Operation', 'frühelektive Operation', 'elektive Operation')),
    Versichertennummer VARCHAR(10),
    SteuerID CHAR(11) NOT NULL CHECK (length(SteuerID)=11),
    Name VARCHAR(255) NOT NULL,
    Raumnummer UTINYINT NOT NULL,
    Datum DATE NOT NULL,
    Startzeit TIME NOT NULL,
    ist_Vollnarkose BOOLEAN NOT NULL,
    Endzeit TIME NOT NULL CHECK (Endzeit > Startzeit AND Endzeit <= (Startzeit + INTERVAL '9' HOUR) AND Endzeit >= (Startzeit + INTERVAL '15' MINUTE)),
    FOREIGN KEY (Raumnummer, SteuerID, Name) REFERENCES "OP-Saal"(Raumnummer, SteuerID, Name),
    FOREIGN KEY (Versichertennummer) REFERENCES Patient_in(Versichertennummer)
);

/*CREATE TABLE OP(
    Nummer UUID NOT NULL PRIMARY KEY,
    Dringlichkeit TEXT NOT NULL,
    CHECK (Dringlichkeit IN ('Notoperation', 'dringliche Operation', 'frühelektive Operation', 'elektive Operation')),
    ist_Vollnarkose BOOLEAN NOT NULL,
    Datum DATE NOT NULL,
    Startzeit TIMESTAMP NOT NULL,
    Endzeit TIMESTAMP NOT NULL,
    CHECK (Endzeit > Startzeit AND Endzeit <= (Startzeit + INTERVAL '9' HOUR)),
    Versichertennummer CHAR(10),
    Raumnummer UTINYINT NOT NULL,
    FOREIGN KEY (Raumnummer) REFERENCES "OP-Saal"(Raumnummer),
    FOREIGN KEY (Versichertennummer) REFERENCES Patient_in(Versichertennummer)
);*/

CREATE TABLE hat (
    ICD TEXT(3) NOT NULL,
    ID UINTEGER NOT NULL,
    Versichertennummer TEXT(20) NOT NULL,
    PRIMARY KEY (ICD, ID),
    FOREIGN KEY (ID) REFERENCES Termin(ID),
    FOREIGN KEY (ICD) REFERENCES Diagnose(ICD),
    FOREIGN KEY (Versichertennummer) REFERENCES Patient_in(Versichertennummer)
); 
