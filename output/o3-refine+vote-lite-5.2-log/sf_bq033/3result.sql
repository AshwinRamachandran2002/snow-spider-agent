WITH months AS (
    -- generate one row for every month from 2008‑01 through 2022‑12 (180 months)
    SELECT DATE_TRUNC('month', DATEADD(month, SEQ4(), '2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
iot_counts AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_DATE("filing_date"::TEXT, 'YYYYMMDD')
        )                                             AS month_start,
        COUNT(*)                                      AS filings
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
    GROUP BY month_start
)
SELECT
    TO_VARCHAR(m.month_start, 'YYYY-MM') AS "month",
    COALESCE(i.filings, 0)               AS "filings"
FROM months m
LEFT JOIN iot_counts i
       ON m.month_start = i.month_start
ORDER BY m.month_start;