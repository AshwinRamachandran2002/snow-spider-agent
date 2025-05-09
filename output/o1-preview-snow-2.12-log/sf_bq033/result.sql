WITH months AS (
  SELECT
    DATEADD(
      month,
      ROW_NUMBER() OVER (ORDER BY NULL) - 1,
      '2008-01-01'::DATE
    ) AS "month_start"
  FROM TABLE(GENERATOR(ROWCOUNT => 180))
)
SELECT
  TO_CHAR(m."month_start", 'Mon') AS "Month",
  EXTRACT(year FROM m."month_start") AS "Year",
  COALESCE(c."num_filings", 0) AS "Number_of_filings"
FROM
  months m
LEFT JOIN (
  SELECT
    DATE_TRUNC('month', TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD')) AS "filing_month",
    COUNT(DISTINCT t."publication_number") AS "num_filings"
  FROM
    "PATENTS"."PATENTS"."PUBLICATIONS" t,
    LATERAL FLATTEN(input => t."abstract_localized") f
  WHERE
    t."country_code" = 'US'
    AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') BETWEEN '2008-01-01' AND '2022-12-31'
    AND LOWER(f.value:"text"::STRING) LIKE '%internet of things%'
    AND f.value:"language"::STRING = 'en'
  GROUP BY
    "filing_month"
) c ON m."month_start" = c."filing_month"
ORDER BY
  m."month_start";