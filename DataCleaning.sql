
-- Data cleaning required in Artworks csv



-- 1. creating junction tables as having comma separated values is not good practice in RDBMS
-- we are having constituent IDs and artists names as comma-separated so splitted them by string_split
-- here one object can have mutliple constituent ids and artists.

CREATE TABLE Artwork_Artist_Junction (
    ObjectID INT,              -- FK to ArtworksRaw table
    ConstituentID INT    -- FK to Artists table
	FOREIGN KEY (ObjectId) REFERENCES Artworks(ObjectId),
    FOREIGN KEY (ConstituentId) REFERENCES Artists(ConstituentId)
);

INSERT INTO Artwork_Artist_Junction (ObjectID, ConstituentID)
SELECT 
    ObjectID,
    TRY_CAST(TRIM(value) AS INT) AS ConstituentID
FROM ArtworksRaw
CROSS APPLY STRING_SPLIT(ConstituentID, ',')
WHERE TRY_CAST(TRIM(value) AS INT) IS NOT NULL;

CREATE TABLE Artwork_ArtistName_Junction (
    ObjectID INT,     -- From ArtworksRaw
    ArtistName VARCHAR(max)  -- Individual artist name
	FOREIGN KEY (ObjectId) REFERENCES Artworks(ObjectId)
);

INSERT INTO Artwork_ArtistName_Junction (ObjectID, ArtistName)
SELECT 
    ObjectID,
    LTRIM(RTRIM(value)) AS ArtistName
FROM ArtworksRaw
CROSS APPLY STRING_SPLIT(Artist, ',')
WHERE LTRIM(RTRIM(value)) <> '';


select * from Artwork_Artist_Junction -- normalised constituent IDs one to many
select * from Artwork_ArtistName_Junction-- normalised Artists one to many

select 
	OBJECTID,
	count(*)
from Artwork_ArtistName_Junction
group by OBJECTID
having count(*)>1

-- 2. Date acquired null values in some rows. Adding another column to add Y and N flags.

select  top 10 * from ArtworksRaw

ALTER TABLE ArtworksRaw 
ADD IsDateAcquiredAvailable CHAR(1);

UPDATE ArtworksRaw
SET IsDateAcquiredAvailable = 
    CASE WHEN DateAcquired IS NULL THEN 'N' ELSE 'Y' END;

--3. Medium- comma separated values and some weird values like a. b. 1.2. like indexing done in single field

select  top 10 * from ArtworksRaw

ALTER TABLE ArtworksRaw 
ADD CleanMedium NVARCHAR(MAX);

UPDATE ArtworksRaw
SET CleanMedium = LTRIM(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Medium,
    '.a:', ''), '.b:', ''), '.c:', ''), '.d:', ''), '.1:', '')
);

UPDATE ArtworksRaw
SET CleanMedium = REPLACE(REPLACE(REPLACE(CleanMedium, '(', ''), ')', ''), ';', ',')


--Normalized

CREATE TABLE Artwork_Medium_Junction (
    ObjectID INT,
    Medium NVARCHAR(MAX),
	FOREIGN KEY (ObjectId) REFERENCES Artworks(ObjectId)
);

Insert into Artwork_Medium_Junction(ObjectID, Medium)
select
	ObjectID,
	LTRIM(RTRIM(value)) as CleanMedium
from ArtworksRaw
CROSS APPLY STRING_SPLIT(CleanMedium, ',')
WHERE LTRIM(RTRIM(value)) <> '';

select * from Artwork_Medium_Junctions

--4. Nationality- values are in parentheses (American), null also shown as ()

CREATE TABLE Nationality (
    NationalityID INT IDENTITY PRIMARY KEY,
    NationalityName NVARCHAR(100) UNIQUE
);

CREATE TABLE ArtworkNationality (
    ObjectID INT,
    NationalityID INT,
    FOREIGN KEY (ObjectID) REFERENCES Artworks(ObjectID),
    FOREIGN KEY (NationalityID) REFERENCES Nationality(NationalityID)
);

INSERT INTO Nationality (NationalityName)
SELECT DISTINCT TRIM(value) AS CleanNationality
FROM ArtworksRaw
CROSS APPLY STRING_SPLIT(
    REPLACE(REPLACE(REPLACE(Nationality, ') (', '|'), '(', ''), ')', ''),
    '|'
)
WHERE TRIM(value) <> '';

INSERT INTO ArtworkNationality (ObjectID, NationalityID)
SELECT 
    ar.ObjectID,
    n.NationalityID
FROM ArtworksRaw ar
CROSS APPLY STRING_SPLIT(
    REPLACE(REPLACE(REPLACE(ar.Nationality, ') (', '|'), '(', ''), ')', ''),
    '|'
) AS split
JOIN Nationality n ON n.NationalityName = TRIM(split.value)
WHERE TRIM(split.value) <> '';

select * from Nationality
order by NationalityID

select * from ArtworkNationality
order by ObjectID

select  top 10 * from ArtworksRaw

--- 5. Gender: multiple values in sigle field. values in parenthesis

Create table Artworks_Gender(
	objectId int,
	Gender Varchar(max),
	FOREIGN Key (ObjectId) references Artworks(ObjectId)
	)

Insert Into Artworks_Gender(ObjectId, Gender)
Select 
	objectId,
	Trim(value) as Gender
From ArtworksRaw
CROSS APPLY STRING_SPLIT(
    REPLACE(REPLACE(REPLACE(Gender, ') (', '|'), '(', ''), ')', ''),
    '|')
where TRIM(value) <> '';

select * from Artworks_Gender

select gender from ArtworksRaw
-- 6. Cataloged- shown as 1& 0, need to show as Y and N

ALTER TABLE ArtworksRaw 
ADD CatalogedFlag CHAR(1);

UPDATE ArtworksRaw
SET CatalogedFlag = 
    CASE WHEN Cataloged = 1 THEN 'Y'
         WHEN Cataloged = 0 THEN 'N'
         ELSE NULL END;

select top 10* from ArtworksRaw

-- Creating clean table Artworks so that it will help in further analysis

Create table Artworks(
ObjectId int Primary Key,
Title varchar(max),
DateAcquired datetime,
IsDateAcquiredAvailable char(1),
Department varchar(255),
Classification varchar(255),
AccessionNumber varchar(max),
Catloged bit,
CatlogedFlag char(1),
Onview varchar(max))

Insert Into Artworks(ObjectId, Title, DateAcquired, IsDateAcquiredAvailable, Department, Classification, 
AccessionNumber, Catloged, CatlogedFlag,Onview)
select
	ObjectId, Title, DateAcquired, IsDateAcquiredAvailable, Department, Classification, 
AccessionNumber, Cataloged, CatalogedFlag,Onview
From
	ArtworksRaw

alter table artworksraw
add cleandate int

UPDATE artworksraw
SET cleandate = TRY_CAST(
    SUBSTRING(Date, PATINDEX('%[1-2][0-9][0-9][0-9]%', Date), 4) 
    AS INT
)
WHERE PATINDEX('%[1-2][0-9][0-9][0-9]%', Date) > 0;


alter table artworks
add YearOfCreation int

update A
set A.YearOfCreation=R.cleandate
from Artworks A
join ArtworksRaw R ON A.ObjectId = R.ObjectId

UPDATE Artworks
SET YearOfCreation = 
    CASE 
        WHEN YearOfCreation IS NOT NULL THEN YearOfCreation
        WHEN ISDATE(DateAcquired) = 1 THEN YEAR(DateAcquired)
        ELSE NULL
    END;

-- Begin date and end date has parenthesis

alter table ArtworksRaw
add CleanBeginDate int

update ArtworksRaw
set CleanBeginDate = Try_cast(REPLACE(REPLACE(BeginDate, '(', ''), ')', '') as int)

select CleanBeginDate from ArtworksRaw

alter table ArtworksRaw
add CleanEndDate int

Update ArtworksRaw
Set CleanEndDate = TRY_CAST(Replace(Replace(EndDate, '(', ''), ')', '') as int)

select * from Artworks

select top 10 * from ArtworksRaw
select date from artworksraw
select * from Artworks

select top 10 * from Artists

/*

table structure having many to many relationship with object ID

1. Artist : Artwork_ArtistName_Junction
2. ConstituentID: Artwork_Artist_Junction
3. Nationality: ArtworkNationality
4. Gender: Artworks_Gender
5. Medium: Artwork_Medium_Junction

6. Artwrorks : ObjectId, Title, DateAcquired, IsDateAcquiredAvailable, Department, Classification, 
AccessionNumber, Catloged, CatlogedFlag,Onview

7. Artists: Constituent ID, Displayname(artist), Artist bio, Nationality, gender, Begin, end, Wiki, ULAN
*/
