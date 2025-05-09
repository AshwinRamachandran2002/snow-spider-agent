WITH months AS (
    SELECT
        TO_CHAR(DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, TO_DATE('2008-01-01', 'YYYY-MM-DD')), 'YYYYMM') AS "filing_year_month"
    FROM
        TABLE(GENERATOR(ROWCOUNT => 180))
),
filings AS (
    SELECT 
        SUBSTR(t."filing_date"::VARCHAR, 1, 6) AS "filing_year_month",
        COUNT(DISTINCT t."publication_number") AS "num_filings"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(INPUT => t."abstract_localized") f
    WHERE t."country_code" = 'US'
      AND LOWER(f.value:"text"::STRING) LIKE '%internet of things%'
      AND t."filing_date" BETWEEN 20080101 AND 20221231
    GROUP BY "filing_year_month"
)
SELECT
    TO_CHAR(TO_DATE(m."filing_year_month" || '01', 'YYYYMMDD'), 'Month') AS "Month",
    TO_NUMBER(SUBSTR(m."filing_year_month", 1, 4)) AS "Year",
    COALESCE(f."num_filings", 0) AS "Number_of_filings"
FROM months m
LEFT JOIN filings f ON m."filing_year_month" = f."filing_year_month"
ORDER BY m."filing_year_month";