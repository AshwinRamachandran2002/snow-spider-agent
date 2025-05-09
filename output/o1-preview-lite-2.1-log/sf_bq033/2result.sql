WITH RECURSIVE months AS (
    SELECT DATE '2008-01-01' AS first_of_month
    UNION ALL
    SELECT DATEADD(month, 1, first_of_month) AS first_of_month
    FROM months
    WHERE first_of_month < DATE '2022-12-01'
),
date_list AS (
    SELECT
        EXTRACT(YEAR FROM first_of_month) AS "Year",
        EXTRACT(MONTH FROM first_of_month) AS "Month"
    FROM months
),
publications AS (
    SELECT DISTINCT
        t."publication_number",
        TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') AS filing_date
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."abstract_localized") f
    WHERE t."country_code" = 'US'
      AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
      AND t."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value::VARIANT:"text"::STRING ILIKE '%internet of things%'
),
pub_counts AS (
    SELECT
        EXTRACT(YEAR FROM filing_date) AS "Year",
        EXTRACT(MONTH FROM filing_date) AS "Month",
        COUNT(*) AS Num_Publications
    FROM publications
    GROUP BY "Year", "Month"
)
SELECT
    d."Year",
    d."Month",
    COALESCE(p.Num_Publications, 0) AS Num_Publications
FROM date_list d
LEFT JOIN pub_counts p ON d."Year" = p."Year" AND d."Month" = p."Month"
ORDER BY d."Year", d."Month";