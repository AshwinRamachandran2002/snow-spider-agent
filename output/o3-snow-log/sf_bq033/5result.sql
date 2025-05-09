WITH month_calendar AS (   -- complete list of months 2008-01 .. 2022-12
    SELECT
        DATEADD(month, SEQ4(), TO_DATE('2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))            -- 15 years * 12 months
),
iot_us_filings AS (       -- IoT-related US publications filed in each month
    SELECT
        DATE_TRUNC('month',
            TO_DATE(TO_CHAR("filing_date"), 'YYYYMMDD')
        )                                   AS month_start,
        COUNT(*)                           AS filings_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::string) LIKE '%internet of things%'
    GROUP BY month_start
)
SELECT
    TO_CHAR(mc.month_start, 'YYYY-MM')     AS "filing_month",
    COALESCE(f.filings_cnt, 0)             AS "iot_publications"
FROM month_calendar mc
LEFT JOIN iot_us_filings f
       ON mc.month_start = f.month_start
ORDER BY mc.month_start;