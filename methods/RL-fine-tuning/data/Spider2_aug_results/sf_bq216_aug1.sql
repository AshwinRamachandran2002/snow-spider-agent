-- Task: Find all patents filed in the same year as 'US-9741766-B2' and provide their publication numbers.

WITH base_patent_year AS (
  SELECT 
    EXTRACT(YEAR, TRY_TO_DATE(CAST("filing_date" AS STRING), 'YYYYMMDD')) AS focal_filing_year
  FROM
    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
  WHERE
    "publication_number" = 'US-9741766-B2'
    AND TRY_TO_DATE(CAST("filing_date" AS STRING), 'YYYYMMDD') IS NOT NULL
)
SELECT
  p."publication_number"
FROM
  PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
  JOIN base_patent_year bp ON
    EXTRACT(YEAR, TRY_TO_DATE(CAST(p."filing_date" AS STRING), 'YYYYMMDD')) = bp.focal_filing_year
WHERE
  p."publication_number" != 'US-9741766-B2'
  AND TRY_TO_DATE(CAST(p."filing_date" AS STRING), 'YYYYMMDD') IS NOT NULL
LIMIT 100;