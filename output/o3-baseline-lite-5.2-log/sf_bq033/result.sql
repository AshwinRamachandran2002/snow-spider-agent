WITH months AS (                                                     -- all months Jan‑2008 .. Dec‑2022
    SELECT DATEADD(month, seq4(), TO_DATE('2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))                         -- 15 years * 12 months = 180 rows
),
iot_filings AS (                                                     -- IoT‑related US publications
    SELECT
        DATE_TRUNC('month',
                   TO_DATE(TO_CHAR("filing_date"), 'YYYYMMDD')) AS month_start,
        COUNT(*) AS filing_count
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
    GROUP BY month_start
)
SELECT
    m.month_start,
    COALESCE(f.filing_count, 0) AS iot_publications_filed
FROM months AS m
LEFT JOIN iot_filings AS f
       ON m.month_start = f.month_start
ORDER BY m.month_start;