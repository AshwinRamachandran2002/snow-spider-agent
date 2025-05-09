WITH cal AS (   -- calendar months from 2008‑01 to 2022‑12
    SELECT
        TO_CHAR(
            DATEADD(month, seq4(), DATE '2008-01-01'),
            'YYYYMM'
        )::INTEGER AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 180))          -- 15 years × 12 months
),
iot AS (        -- U.S. publications whose abstract mentions “internet of things”
    SELECT
        FLOOR("filing_date" / 100)::INTEGER              AS month,
        COUNT(DISTINCT "publication_number") AS num_filings
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY month
)
SELECT
    cal.month,
    COALESCE(iot.num_filings, 0) AS num_filings
FROM cal
LEFT JOIN iot USING (month)
ORDER BY cal.month;