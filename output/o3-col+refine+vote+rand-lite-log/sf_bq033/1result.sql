WITH "calendar" AS (   -- every month from 2008-01 through 2022-12
    SELECT
        TO_CHAR(
            DATE_TRUNC('month', DATEADD(month, SEQ4(), '2008-01-01'))
        , 'YYYYMM')            AS "month_id"
    FROM TABLE(GENERATOR(ROWCOUNT => 180))      -- 15 years × 12 months
),

"iot_counts" AS (       -- IoT-related U.S. publications per filing month
    SELECT
        TO_CHAR(
            TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD')
        , 'YYYYMM')            AS "month_id",
        COUNT(DISTINCT p."publication_number")  AS "num_filings"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY TO_CHAR(TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD'), 'YYYYMM')
)

SELECT
    cal."month_id",
    COALESCE(cnt."num_filings", 0) AS "iot_us_filings"
FROM "calendar" cal
LEFT JOIN "iot_counts" cnt
  ON cal."month_id" = cnt."month_id"
ORDER BY cal."month_id";