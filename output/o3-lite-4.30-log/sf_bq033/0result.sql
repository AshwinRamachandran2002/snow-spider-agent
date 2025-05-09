WITH calendar AS (   -- months from 2008‑01 through 2022‑12 (15*12 = 180)
    SELECT TO_CHAR(
               DATEADD(month, seq4(), '2008-01-01'::DATE),
               'YYYY-MM'
           ) AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),
iot AS (   -- U.S. filings whose abstract contains “internet of things”
    SELECT
        TO_CHAR(TO_DATE(p."filing_date"::STRING, 'YYYYMMDD'), 'YYYY-MM') AS month,
        p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER(f.value:"text"::STRING) LIKE '%internet%of%things%'
)
SELECT
    c.month,
    COALESCE(COUNT(DISTINCT i."publication_number"), 0) AS num_filings
FROM calendar c
LEFT JOIN iot i
       ON c.month = i.month
GROUP BY c.month
ORDER BY c.month;