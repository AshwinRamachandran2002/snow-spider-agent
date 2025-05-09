WITH months AS (
    /* 15 years × 12 months = 180 rows, covering 2008-01 through 2022-12 */
    SELECT 
        TO_CHAR(DATEADD(month, seq4(), '2008-01-01'::DATE), 'YYYYMM') AS "yyyymm"
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))
),
iot AS (
    SELECT
        SUBSTR(TO_CHAR(p."filing_date"), 1, 6)          AS "yyyymm",
        COUNT(DISTINCT p."publication_number")          AS "iot_filings"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value::VARIANT:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY SUBSTR(TO_CHAR(p."filing_date"), 1, 6)
)
SELECT
    m."yyyymm",
    COALESCE(i."iot_filings", 0) AS "iot_filings"
FROM months m
LEFT JOIN iot i
       ON m."yyyymm" = i."yyyymm"
ORDER BY m."yyyymm";