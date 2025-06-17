/*
1. Artist : Artwork_ArtistName_Junction
2. ConstituentID: Artwork_Artist_Junction
3. Nationality: ArtworkNationality
4. Gender: Artworks_Gender
5. Medium: Artwork_Medium_Junction
6. Artwrorks : ObjectId, Title, DateAcquired, IsDateAcquiredAvailable, Department, Classification, 
AccessionNumber, Catloged, CatlogedFlag,Onview
7. Artists: Constituent ID, Displayname(artist), Artist bio, Nationality, gender, Begin, end, Wiki, ULAN
*/

select * from Artwork_ArtistName_Junction

select * from Artwork_Artist_Junction

select * from ArtworkNationality

select * from Artworks_Gender

select * from Artwork_Medium_Junction

select * from Artworks

select * from Artists

--1. How modern are the artworks at the Museum?

SELECT 
	case 
	when YearOfCreation >= 2000 Then '21st Century'
	when YearOfCreation >= 1900 Then '20Th Century'
	when YearOfCreation >= 1800 Then '19Th Century'
	when YearOfCreation >= 1700 Then '18Th Century'
	else 'Earlier or Unknown'
	end as Period,
    COUNT(*) AS TotalArtworks
FROM 
    Artworks
GROUP BY 
    case 
	when YearOfCreation >= 2000 Then '21st Century'
	when YearOfCreation >= 1900 Then '20Th Century'
	when YearOfCreation >= 1800 Then '19Th Century'
	when YearOfCreation >= 1700 Then '18Th Century'
	else 'Earlier or Unknown'
	end
ORDER BY 
    Period;

/*
Art created n MoMA is more modern, having 150181 Artworks created in 20th and 21st centuries.

Period	TotalArtworks
18Th Century	87
19Th Century	6911
20Th Century	132933
21st Century	17248
Earlier or Unknown	451
*/

--2. Which artists are featured the most?

SELECT
	A.ConstituentID,
    A.DisplayName AS ArtistName,
	count(*) as NoOfArtworks
FROM
    Artwork_Artist_Junction AJ
JOIN
    Artworks AR ON AJ.ObjectID = AR.ObjectID
JOIN
    Artists A ON AJ.ConstituentID = A.ConstituentID
Group by
	A.ConstituentID,
	A.DisplayName
ORDER BY
	NoOfArtworks desc

/*
These are top 10 artists featured most out of 14423 artists

7166	Ludwig Mies van der Rohe	15532
229	Eugène Atget	5031
710	Louise Bourgeois	3381
8595	Unidentified photographer	2837
3048	Ellsworth Kelly	2205
1633	Jean Dubuffet	1437
2002	Lee Friedlander	1338
4609	Pablo Picasso	1329
1055	Marc Chagall	1174
3832	Henri Matisse	1071
*/

-- 3. Are there any trends in the dates of acquisition?

select
	case
	when year(DateAcquired) >= 2000 then '21st Century'
	when year(DateAcquired) >= 1900 then '20th Century'
	when year(DateAcquired) >= 1800 then '19th Century'
	when year(DateAcquired) >= 1700 then '18th Century'
	else 'Unknown'
	end as AcquisitionPeriod,
	count(*) as Trend
from Artworks
group by
	case
	when year(DateAcquired) >= 2000 then '21st Century'
	when year(DateAcquired) >= 1900 then '20th Century'
	when year(DateAcquired) >= 1800 then '19th Century'
	when year(DateAcquired) >= 1700 then '18th Century'
	else 'Unknown'
	end
order by 
	Trend desc

/* min dateacquied is 1929 so we can assume MoMA started from 1929

lowest acquisitions 1929-	9
Highest acqusitions 2024-	862

AcquisitionPeriod	Trend
20th Century		94908
21st Century		55973
Unknown				6749
*/

--total
SELECT 
    YEAR(DateAcquired) AS AcquisitionYear,
    COUNT(*) AS NoOfArtworksAcquired
FROM 
    Artworks
WHERE 
    DateAcquired IS NOT NULL
GROUP BY 
    YEAR(DateAcquired)
ORDER BY 
    AcquisitionYear;

--lowest
SELECT 
	Top 1
    YEAR(DateAcquired) AS AcquisitionYear,
    COUNT(*) AS NoOfArtworksAcquired
FROM 
    Artworks
WHERE 
    DateAcquired IS NOT NULL
GROUP BY 
    YEAR(DateAcquired)
ORDER BY 
    AcquisitionYear;

-- highest
SELECT 
	Top 1
    YEAR(DateAcquired) AS AcquisitionYear,
    COUNT(*) AS NoOfArtworksAcquired
FROM 
    Artworks
WHERE 
    DateAcquired IS NOT NULL
GROUP BY 
    YEAR(DateAcquired)
ORDER BY 
    AcquisitionYear desc


--4. What types of artwork are most common?

select
	Medium,
	COUNT(*) as Mediums
from
	Artwork_Medium_Junction
where Medium is not null
group by Medium
order by Mediums desc

/* These are top 10 out of 26068 rows
Medium					Count
Gelatin silver print	19041
Lithograph				10609
Pencil on paper			7281
Albumen silver print	4850
printed in black		4062
Etching					3450
printed in color		3278
pencil					3121
Pencil on tracing paper	2611
ink						2573
*/

select
	classification,
	count(*) as NoOfClassifications
from
	Artworks
group by
	Classification
order by NoOfClassifications desc

/* These ar highest classifiied art forms
classification				NoOfClassifications
Photograph					34770
Print						32590
Illustrated Book			27834
Mies van der Rohe Archive	16305
Drawing						14234
Design						12307
Architecture				4158
Painting					2430
Video						2420
Notebook					1965
*/

/* Recommended analysis from my end
5. What is the geographic or cultural diversity of artists in the collection?

Why it’s important:
Museums increasingly aim for inclusive collections. This analysis helps understand representation and guide curatorial strategy.
*/

SELECT 
    NN.NationalityName,
    G.Gender,
    COUNT(DISTINCT C.ConstituentID) AS NoOfArtists
FROM 
    Artwork_Artist_Junction C
JOIN 
    ArtworkNationality N ON N.ObjectID = C.ObjectID
join Nationality NN on NN.NationalityID= N.NationalityID
JOIN 
    Artworks_Gender G ON G.ObjectID = C.ObjectID
GROUP BY 
    NN.NationalityName, G.Gender
ORDER BY 
    --NN.NationalityName asc,
	NoOfArtists DESC;

SELECT 
    NN.NationalityName,
    COUNT(DISTINCT C.ConstituentID) AS NoOfArtists
FROM 
    Artwork_Artist_Junction C
JOIN 
    ArtworkNationality N ON N.ObjectID = C.ObjectID
join Nationality NN on nn.NationalityID=n.NationalityID
GROUP BY 
    NN.NationalityName
ORDER BY 
    NoOfArtists DESC;

/* top 10 countries
American	6472
German	1775
British	1665
French	1578
Italian	1020
Japanese	926
Swiss	818
Dutch	661
Austrian	580
Canadian	521

*/

SELECT 
    G.Gender,
    COUNT(DISTINCT C.ConstituentID) AS NoOfArtists
FROM 
    Artwork_Artist_Junction C
JOIN 
    Artworks_Gender G ON G.ObjectID = C.ObjectID
GROUP BY 
    G.Gender
ORDER BY 
    NoOfArtists DESC;

/*
male	11447
female	4358
non-binary	8
transgender woman	1
female transwoman	1
gender non-conforming	1
*/
