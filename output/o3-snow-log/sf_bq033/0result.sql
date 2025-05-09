WITH months AS (
    /* create one row for every month from Jan-2008 through Dec-2022 (15*12 = 180 rows) */
    SELECT 
        DATE_TRUNC('month',
                   DATEADD(month, seq4(), TO_DATE('2008-01-01'))) AS month_date
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))
),
iot_filings AS (
    /* count US applications whose abstract mentions “internet of things” */
    SELECT
        DATE_TRUNC('month',
                   TO_DATE("filing_date"::STRING, 'YYYYMMDD')) AS month_date,
        COUNT(*) AS cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER(TO_VARCHAR("abstract_localized")) LIKE '%internet of things%'
    GROUP BY 1
)
SELECT
    TO_CHAR(m.month_date, 'YYYY-MM') AS "year_month",
    COALESCE(i.cnt, 0)          AS "filings"
FROM months m
LEFT JOIN iot_filings i
       ON m.month_date = i.month_date
ORDER BY m.month_date;