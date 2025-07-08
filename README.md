# DigitalHumanities
Cleaned and transformed museum artwork data using SQL and Power Query to resolve data quality issues across artist names, acquisition dates, nationalities, and mediums. Enabled structured analysis by designing relationships and preparing the dataset for BI dashboarding and advanced querying.

Artworks Digital Humanities Project – Key Numbers & Metrics
1. Total records: ~12,000 artworks

2. Cataloged column: ~47% initially marked as cataloged (needed cleanup)

3. Missing metadata:

  Artist: ~3,000 null or unnamed

  Nationality: ~6,000 missing

  Gender: ~5,000 missing or inconsistent

  Medium: 700+ distinct variations (e.g., inconsistent values like “Oil on Canvas”, “oil on canvas”)

4. DateAcquired: Wide range with inconsistencies; many NULLs and variations like “c. 2001”

5. Cleaned values for: Title, ArtistName, Nationality, Gender, Medium, Date

6. Post-cleaning impact:

  Metadata completeness improved by ~40%

  ~95% of records normalized for the Medium and Artist fields

  Created KPIs for cataloging %, acquisition trends by decade, and diversity (gender/nationality)

