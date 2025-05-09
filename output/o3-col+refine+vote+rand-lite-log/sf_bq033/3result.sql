WITH iot_by_month AS (
    SELECT
        SUBSTR(TO_VARCHAR(p."filing_date"), 1, 6) AS "yyyy_mm",
        COUNT(*)                                   AS "iot_filings"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND f.value:"language"::STRING = 'en'
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
    GROUP BY 1
),
calendar_months AS (
    SELECT
        TO_CHAR(DATEADD(month, seq4(), '2008-01-01'::DATE), 'YYYYMM') AS "yyyy_mm"
    FROM TABLE(GENERATOR(ROWCOUNT => 12 * 15))    -- 2008-01 through 2022-12  (15 years * 12 months)
)
SELECT
    cal."yyyy_mm",
    COALESCE(iot."iot_filings", 0) AS "iot_filings"
FROM calendar_months cal
LEFT JOIN iot_by_month iot
       ON cal."yyyy_mm" = iot."yyyy_mm"
ORDER BY cal."yyyy_mm";