select top 10 * from artworksraw

select top 10 * from Artworks

select top 10 * from Artists

select * from Artwork_Artist_Junction

select * from Artwork_ArtistName_Junction

select * from Artwork_Medium_Junction

select * from ArtworkNationality

select * from Artworks_Gender


/*
1. Artwork Lifespan Analysis
Goal: Analyze how long after creation an artwork was acquired.
Insight: Helps assess if the museum focuses on historical or contemporary acquisitions.
*/

select
	Objectid,
	YEAR(DateAcquired) as YearOfAcquisition,
	YearOfCreation,
	(YEAR(DateAcquired)-YearOfCreation) as Lifespan
from 
	Artworks
where
	YearOfCreation is not null and DateAcquired is not null
order by
	Lifespan desc

/* few rows are coming like this- definitely there is data inconsistncy issues
64242	1930	1944	-14
471830	2010	2022	-12
60807	1959	1969	-10
65161	1953	1961	-8
8338	1970	1977	-7
118215	1981	1988	-7
98833	1999	2004	-5
103617	2006	2011	-5
282994	2010	2015	-5
98832	1999	2003	-4
*/

select * from ArtworksRaw
where ObjectId = 64242

SELECT 
    ObjectID, 
    Title,
    YearOfCreation,
    YEAR(DateAcquired) AS AcquiredYear
FROM 
    Artworks
WHERE 
    YearOfCreation IS NOT NULL
    AND DateAcquired IS NOT NULL
    AND YearOfCreation > YEAR(DateAcquired);

-- 90 rows are But I will flag them as inconsistent and there. 
-- I don't know for sure which one is wrong so for analysis I'm skipping these. 
-- Also DateAcquired I'm keeping them as null.

ALTER TABLE Artworks ADD IsDateInconsistent BIT;

UPDATE Artworks
SET IsDateInconsistent = 1
WHERE YearOfCreation > YEAR(DateAcquired);

UPDATE Artworks
SET YearOfCreation = NULL
WHERE YearOfCreation > YEAR(DateAcquired);


with ArtworkCount as
(select
	case
	when (YEAR(DateAcquired)-YearOfCreation) >=150 then 'More than 150 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 100 and 149 then 'More than 100 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 50 and 99 then 'More than 50 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 1 and 49 then 'Less than 50 Years since creation'
	else 'Contemporary'
	end as Lifespan,
	COUNT(*) as NoOfArtworks
from 
	Artworks
where
	YearOfCreation is not null and DateAcquired is not null
group by
	case
	when (YEAR(DateAcquired)-YearOfCreation) >=150 then 'More than 150 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 100 and 149 then 'More than 100 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 50 and 99 then 'More than 50 Years since creation'
	when (YEAR(DateAcquired)-YearOfCreation) between 1 and 49 then 'Less than 50 Years since creation'
	else 'Contemporary'
	end
	)
Select 
	Lifespan,
	NoOfArtworks,
	ROUND(100.0 * NoOfArtworks/SUM(NoOfArtworks) over(), 2) as PercentTotal
from
	ArtworkCount
order by
	NoOfArtworks desc

/*Museum is focusing more modern, contemporary and recent art works. It lacks in acquiring historical and classical works.

Lifespan							NoOfArtworks	PercentTotal
Less than 50 Years since creation	111103			73.680000000000
More than 50 Years since creation	25366			16.820000000000
Contemporary						10237			6.790000000000
More than 100 Years since creation	3777			2.500000000000
More than 150 Years since creation	308				0.200000000000 
*/

/*
2.Artist Career Span
Goal: Calculate the active span of each artist (EndDate - BeginDate).
Insight: Understand whether the museum favors early, mid, or late-career works.
*/

with Span as(
Select
	ConstituentId,
	DisplayName,
	BeginDate,
	EndDate,
	case
	when EndDate is null or EndDate = 0 then YEAR(getdate())-BeginDate
	else EndDate-BeginDate
	end as Active_Span
from
	Artists
where BeginDate is not null
)
select 
	case
	when Active_Span >=100 then 'Veteran Talent'
	when Active_Span between 50 and 99 then 'Seasoned Talent'
	Else 'Young Talent'
	end as AgeSpan,
	Count(*) as Artists
from 
	Span
group by 
	case
	when Active_Span >=100 then 'Veteran Talent'
	when Active_Span between 50 and 99 then 'Seasoned Talent'
	Else 'Young Talent'
	end
Order by
	Artists desc

/* Museum Favors late-career works.
AgeSpan			Artists
Seasoned Talent	10229
Veteran Talent	4084
Young Talent	1325
*/

/*
3. Collaboration Networks
Goal: Find artworks with multiple artists.
Insight: Identify frequent collaborators or team-created works.
*/

SELECT 
    ArtistCount,
    COUNT(*) AS NumberOfArtworks
FROM (
    SELECT 
        ObjectId,
        COUNT(ConstituentId) AS ArtistCount
    FROM 
        Artwork_Artist_Junction
    GROUP BY 
        ObjectId
) AS ArtworkArtistCounts
GROUP BY 
    ArtistCount
ORDER BY 
    ArtistCount;

/* The museum's collection is artist-centric, emphasizing individual creativity.

Collaboration exists but is not the norm.

A few extreme outliers might warrant review, as they could indicate data quality issues or represent special projects.

ArtistCount	NumberOfArtworks
1	148445
2	4814
3	1851
4	305
5	264
6	268
7	125
8	60
9	17
10	28
11	23
12	21
13	7
14	14
15	6
16	5
17	13
18	6
19	2
20	56
21	6
22	5
23	2
24	2
25	2
26	1
27	3
28	1
29	1
30	4
31	2
47	1
132	1
*/

/*
4. Medium Usage Trends
Goal: Track how the use of different mediums evolved over time.
Insight: Identify shifts in artistic materials across centuries.
*/

SELECT 
    M.CleanMedium, 
    DATEPART(YEAR, A.DateAcquired) AS YearAcquired, 
    COUNT(*) AS UsageCount
FROM ArtworksRaw M
JOIN Artworks A ON M.ObjectID = A.ObjectID
where CleanMedium is not null and A.DateAcquired is not null
GROUP BY M.CleanMedium, DATEPART(YEAR, A.DateAcquired)
ORDER BY YearAcquired, UsageCount desc;

/* We can see Trends of different mediums over time.

Pencil on paper						1968	5352
Albumen silver print				1968	3774
Pencil on tracing paper				1968	1328
Pencil and colored pencil on paper	1968	1060
Lithograph							1974	986
Gelatin silver print				2019	964
Gelatin silver print				2013	892
Gelatin silver print				2000	880
Gelatin silver print				2015	796
Gelatin silver print				2017	768
Page from a spiral-bound sketchbook 
with pencil on paper				2020	504
Standard-definition 
video (color, sound)				2024	39
Pencil on torn paper; 
one from a series of sixty-one sheets	2024	32
*/

-- 5. 

SELECT COUNT(*) 
FROM Artworks
WHERE CatlogedFlag = 'N' OR Catloged IS NULL;

SELECT COUNT(*) 
FROM Artworks
WHERE Onview IS not NULL;

SELECT 
  COUNT(*) AS TotalArtworks,
  SUM(CASE WHEN Catloged = 1 THEN 1 ELSE 0 END) AS CatalogedArtworks,
  CAST(SUM(CASE WHEN Catloged = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PercentCataloged
FROM Artworks;

/*
TotalArtworks	CatalogedArtworks	PercentCataloged
157630			100231				63.59
*/

SELECT 
  COUNT(*) AS TotalArtworks,
  SUM(CASE WHEN OnView IS NOT NULL AND OnView <> '' THEN 1 ELSE 0 END) AS OnDisplay,
  CAST(SUM(CASE WHEN OnView IS NOT NULL AND OnView <> '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PercentOnView
FROM Artworks;

/* There will be hidden gems. Only 0.77% artwork is on view
TotalArtworks	OnDisplay	PercentOnView
157630			1210		0.77
*/

SELECT Title, ObjectId
FROM Artworks
WHERE Catloged = 1 AND (OnView IS NULL OR OnView = '');

/*
99062 artworks are catalged but not on display.
 This could be possibly due to 

1. Limited physical space
2. Preserving too old artworks by not keeping them on display
3. Some artworks reserved for exhibition purpose
4. Rotating display so that everytime a person can have new user experience
5. Some artworks can be precious, kept to study culture, loaned to other institutions etc.

*/