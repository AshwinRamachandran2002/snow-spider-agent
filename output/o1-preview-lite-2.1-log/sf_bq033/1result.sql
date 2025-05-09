WITH months AS (
  SELECT
    YEAR(DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2008-01-01')) AS "Year",
    MONTH(DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2008-01-01')) AS "Month"
  FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
counts AS (
  SELECT
    YEAR(TRY_TO_DATE("filing_date"::STRING, 'YYYYMMDD')) AS "Year",
    MONTH(TRY_TO_DATE("filing_date"::STRING, 'YYYYMMDD')) AS "Month",
    COUNT(*) AS "Num_Publications"
  FROM PATENTS.PATENTS.PUBLICATIONS
  WHERE "country_code" = 'US'
    AND "abstract_localized" IS NOT NULL
    AND ARRAY_SIZE("abstract_localized") > 0
    AND "abstract_localized"[0]:"text"::STRING ILIKE '%internet of things%'
    AND TRY_TO_DATE("filing_date"::STRING, 'YYYYMMDD') IS NOT NULL
    AND YEAR(TRY_TO_DATE("filing_date"::STRING, 'YYYYMMDD')) BETWEEN 2008 AND 2022
  GROUP BY "Year", "Month"
)
SELECT m."Year", m."Month", COALESCE(c."Num_Publications", 0) AS "Num_Publications"
FROM months m
LEFT JOIN counts c ON m."Year" = c."Year" AND m."Month" = c."Month"
ORDER BY m."Year", m."Month";