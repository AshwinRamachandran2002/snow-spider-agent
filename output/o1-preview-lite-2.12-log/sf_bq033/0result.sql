WITH numbers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS n
  FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
months AS (
  SELECT
    TO_CHAR(DATEADD(month, n, DATE '2008-01-01'), 'YYYY-MM') AS "Month",
    EXTRACT(YEAR FROM DATEADD(month, n, DATE '2008-01-01')) AS "Year"
  FROM numbers
)
SELECT
  m."Month",
  m."Year",
  COALESCE(c."Number_of_filings", 0) AS "Number_of_filings"
FROM
  months m
LEFT JOIN (
  SELECT
    TO_CHAR(TO_DATE(t."filing_date"::TEXT, 'YYYYMMDD'), 'YYYY-MM') AS "Month",
    COUNT(DISTINCT t."publication_number") AS "Number_of_filings"
  FROM
    PATENTS.PATENTS.PUBLICATIONS t,
    LATERAL FLATTEN(input => t."abstract_localized") f
  WHERE
    t."country_code" = 'US'
    AND t."filing_date" BETWEEN 20080101 AND 20221231
    AND t."filing_date" <> 0
    AND f.value:"text"::STRING ILIKE '%internet of things%'
  GROUP BY
    "Month"
) c ON m."Month" = c."Month"
ORDER BY
  m."Month";