WITH months AS (   -- all months from 2008-01 to 2022-12
    SELECT DATEADD(month, seq4(),
                   DATE '2008-01-01') AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))   -- 15 years * 12 months
), iot_filings AS (   -- U.S. filings whose abstract mentions “internet of things”
    SELECT
        TO_DATE("filing_date"::VARCHAR, 'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND "abstract_localized" IS NOT NULL
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
), monthly_counts AS (
    SELECT
        DATE_TRUNC('month', filing_dt) AS month_start,
        COUNT(*)                      AS filings_count
    FROM iot_filings
    GROUP BY 1
)
SELECT
    TO_CHAR(m.month_start, 'YYYY-MM')      AS month,
    COALESCE(c.filings_count, 0)           AS filings_count
FROM months m
LEFT JOIN monthly_counts c
       ON m.month_start = c.month_start
ORDER BY m.month_start;