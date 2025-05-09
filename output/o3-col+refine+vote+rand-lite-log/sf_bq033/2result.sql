WITH month_series AS (                        -- every month from 2008-01 to 2022-12
    SELECT
        TO_CHAR( DATEADD(month, seq4(), '2008-01-01'::DATE ), 'YYYYMM') AS "filing_month"
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))       -- 15 years × 12 months = 180 rows
),
iot_monthly AS (                               -- IoT-related U.S. publications per month
    SELECT
        LEFT( LPAD(p."filing_date"::STRING, 8, '0'), 6)          AS "filing_month",
        COUNT(*)                                                 AS "num_iot_pubs"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet of things%'    -- phrase in abstract
    GROUP BY "filing_month"
)
SELECT
    m."filing_month",
    COALESCE(i."num_iot_pubs", 0) AS "num_iot_pubs"
FROM month_series m
LEFT JOIN iot_monthly i
       ON m."filing_month" = i."filing_month"
ORDER BY m."filing_month";