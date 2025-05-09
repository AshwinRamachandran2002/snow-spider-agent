/*  IoT-related U.S. publications filed each month (2008-01 – 2022-12)  */
WITH all_months AS (          -- build a complete list of months
    SELECT
        DATE_TRUNC('month',
                    DATEADD('month', seq4(), TO_DATE('2008-01-01'))
               )                     AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))    -- 180 months = 2008-01 … 2022-12
), iot_filings AS (             -- count IoT publications per month
    SELECT
        DATE_TRUNC('month',
                   TO_DATE("filing_date"::string, 'YYYYMMDD')
              )                 AS month_start,
        COUNT(*)                AS filings
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::string) LIKE '%internet of things%'
    GROUP BY month_start
)
SELECT
    m.month_start          AS filing_month,
    COALESCE(f.filings, 0) AS num_us_iot_publications
FROM all_months m
LEFT JOIN iot_filings f
       ON m.month_start = f.month_start
ORDER BY m.month_start;