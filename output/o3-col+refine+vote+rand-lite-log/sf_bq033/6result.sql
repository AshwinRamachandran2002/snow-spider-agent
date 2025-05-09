WITH cal AS (          -- calendar: every month 2008-01 through 2022-12
    SELECT DATEADD(month, seq4(), '2008-01-01') AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 12 * 15))         -- 15 years * 12 months
),
iot AS (              -- monthly count of U.S. filings whose abstract mentions “internet of things”
    SELECT
        TO_CHAR(TO_DATE(p."filing_date"::STRING,'YYYYMMDD'), 'YYYY-MM') AS filing_month,
        COUNT(DISTINCT p."publication_number")                          AS iot_filings
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN (INPUT => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND f.value:"text"::STRING ILIKE '%internet%of%things%'
    GROUP BY 1
)
SELECT
    TO_CHAR(cal.month_start, 'YYYY-MM') AS month,
    COALESCE(iot.iot_filings, 0)        AS iot_filings
FROM cal
LEFT JOIN iot
  ON TO_CHAR(cal.month_start, 'YYYY-MM') = iot.filing_month
ORDER BY month;