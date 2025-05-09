WITH months AS (
    /* generate a list of all months from 2008‑01 to 2022‑12 */
    SELECT 
        DATE_TRUNC('month', DATEADD(month, seq4(), DATE_FROM_PARTS(2008,1,1))) AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 15*12))          -- 15 years * 12 months = 180 rows
), iot_filings AS (
    /* count IoT‑related US publications filed each month */
    SELECT
        DATE_TRUNC(
            'month',
            TO_DATE("filing_date"::STRING,'YYYYMMDD')
        ) AS month,
        COUNT(*) AS cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
    GROUP BY month
)
SELECT 
    m.month,
    COALESCE(f.cnt, 0) AS filings
FROM months m
LEFT JOIN iot_filings f
ON m.month = f.month
ORDER BY m.month;