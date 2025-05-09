WITH iot_us AS (  -- U.S. publications whose abstract contains "internet of things"
    SELECT
        TO_DATE("filing_date"::STRING, 'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
      AND "filing_date" IS NOT NULL
),
month_counts AS (  -- number of such filings per month
    SELECT
        DATE_TRUNC('month', filing_dt) AS month_start,
        COUNT(*) AS filings
    FROM iot_us
    GROUP BY month_start
),
months AS (        -- every month from Jan-2008 through Dec-2022 (180 months)
    SELECT
        DATEADD('month', SEQ4(), DATE '2008-01-01') AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
)
SELECT
    TO_CHAR(months.month_start, 'YYYY-MM') AS "month",
    COALESCE(month_counts.filings, 0)      AS "us_iot_filings"
FROM months
LEFT JOIN month_counts
       ON months.month_start = month_counts.month_start
ORDER BY months.month_start ASC;