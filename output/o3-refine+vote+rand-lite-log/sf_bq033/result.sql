WITH months AS (   -- every month from 2008‑01 through 2022‑12 (180 months)
    SELECT
        DATEADD(month, SEQ4(), TO_DATE('2008-01-01')) AS "month_start"
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
iot_filings AS (   -- U.S. publications whose abstract contains “internet of things”
    SELECT
        DATE_TRUNC('month',
                   TO_DATE("filing_date"::TEXT, 'YYYYMMDD')) AS "month_start",
        COUNT(*) AS "filings_count"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER(CAST("abstract_localized" AS STRING)) LIKE '%internet of things%'
    GROUP BY 1
)
SELECT
    TO_CHAR(m."month_start", 'YYYY-MM') AS "filing_month",
    COALESCE(f."filings_count", 0)      AS "us_iot_publications"
FROM months m
LEFT JOIN iot_filings f
       ON m."month_start" = f."month_start"
ORDER BY m."month_start";