WITH month_series AS (   -- all months from 2008‑01 to 2022‑12
    SELECT
        TO_CHAR(DATEADD(month, seq4(), '2008-01-01'::DATE), 'YYYY-MM') AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 15*12))   -- 180 rows
),
iot_counts AS (          -- IoT‑related U.S. filings per month
    SELECT
        TO_CHAR(TO_DATE(p."filing_date"::STRING, 'YYYYMMDD'), 'YYYY-MM') AS month,
        COUNT(DISTINCT p."publication_number") AS num_filings
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"language"::STRING = 'en'
      AND LOWER(f.value:"text"::STRING) LIKE '%internet%of%things%'
    GROUP BY month
)
SELECT
    m.month,
    COALESCE(i.num_filings, 0) AS num_filings
FROM month_series m
LEFT JOIN iot_counts i USING (month)
ORDER BY m.month;