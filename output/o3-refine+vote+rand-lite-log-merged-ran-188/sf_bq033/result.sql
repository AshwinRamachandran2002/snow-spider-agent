WITH months AS (
    -- one row per month from 2008‑01 through 2022‑12
    SELECT DATEADD(month, SEQ4(), TO_DATE('2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
iot_pubs AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_DATE(TO_CHAR("filing_date"), 'YYYYMMDD')
        ) AS month_start
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::STRING) LIKE '%internet of things%'
)
SELECT
    m.month_start,
    COALESCE(COUNT(i.month_start), 0) AS num_publications
FROM months m
LEFT JOIN iot_pubs i
       ON m.month_start = i.month_start
GROUP BY m.month_start
ORDER BY m.month_start;