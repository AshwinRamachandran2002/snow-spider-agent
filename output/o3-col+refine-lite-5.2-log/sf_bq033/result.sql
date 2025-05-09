-- Monthly count of U.S. IoT‑related patent publications (phrase “internet of things” in abstract)
-- based on filing_date, from 2008‑01 through 2022‑12 (months with zero shown)

WITH iot_by_month AS (
    SELECT
        TO_CHAR(TO_DATE(p."filing_date"::STRING, 'YYYYMMDD'), 'YYYYMM') AS "yyyymm",
        COUNT(*) AS "iot_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS   p
    ,    LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND f.value:"language"::STRING = 'en'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY "yyyymm"
)

SELECT
    cal."yyyymm",
    COALESCE(i."iot_cnt", 0) AS "us_iot_filings"
FROM (
    -- calendar: 2008‑01 through 2022‑12  (15 years × 12 = 180 rows)
    SELECT TO_CHAR(ADD_MONTHS('2008-01-01'::DATE, seq4()), 'YYYYMM') AS "yyyymm"
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
) cal
LEFT JOIN iot_by_month i
       ON cal."yyyymm" = i."yyyymm"
ORDER BY cal."yyyymm";