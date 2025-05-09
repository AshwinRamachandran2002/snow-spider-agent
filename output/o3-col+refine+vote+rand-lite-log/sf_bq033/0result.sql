-- Monthly count of U.S. patent publications whose abstract contains
-- the phrase “internet of things”, filings between 2008-01 and 2022-12
WITH calendar AS (
    -- build one row per month from 2008-01 through 2022-12  (15 years * 12 = 180)
    SELECT
        TO_CHAR(DATEADD(month, SEQ4(), '2008-01-01'::DATE), 'YYYYMM') AS "yyyymm"
    FROM TABLE(GENERATOR(ROWCOUNT => 12*15))
),
iot AS (
    SELECT
        SUBSTR(TO_VARCHAR(p."filing_date"), 1, 6)         AS "yyyymm",
        COUNT(*)                                          AS "iot_filings"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY 1
)
SELECT
    c."yyyymm",
    COALESCE(i."iot_filings", 0) AS "iot_filings"
FROM calendar c
LEFT JOIN iot i USING ("yyyymm")
ORDER BY c."yyyymm";