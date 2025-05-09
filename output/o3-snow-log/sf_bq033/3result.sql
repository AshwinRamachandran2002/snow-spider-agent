WITH months AS (
    /* 180 months from 2008-01 through 2022-12 */
    SELECT DATEADD(month, seq4(), TO_DATE('2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
iot_us_filings AS (
    /* US publications whose abstract mentions “internet of things” */
    SELECT
        DATE_TRUNC(
            month,
            TO_DATE("filing_date"::STRING, 'YYYYMMDD')
        ) AS month_start
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
)
SELECT
    TO_CHAR(m.month_start, 'YYYY-MM') AS month,
    COUNT(i.month_start)              AS filing_count
FROM months m
LEFT JOIN iot_us_filings i
       ON m.month_start = i.month_start
GROUP BY m.month_start
ORDER BY m.month_start NULLS LAST;