WITH RECURSIVE months(m) AS (               -- create YYYYMM list 200801 … 202212
    SELECT 200801 AS m
    UNION ALL
    SELECT CASE
             WHEN RIGHT(m::STRING,2)::INT = 12                -- next year-January
                  THEN (LEFT(m::STRING,4)::INT + 1)*100 + 1
             ELSE m + 1                                       -- next calendar month
           END
    FROM months
    WHERE m < 202212                                          -- stop after 202212
),
iot_pubs AS (                                -- count IoT-related US filings per month
    SELECT
        TO_NUMBER(SUBSTR(p."filing_date"::STRING,1,6))     AS yymm,
        COUNT(DISTINCT p."publication_number")             AS pubs_in_month
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."abstract_localized") a
    WHERE p."country_code" = 'US'
      AND a.value:"text"::STRING ILIKE '%internet of things%'   -- IoT phrase
      AND TO_NUMBER(SUBSTR(p."filing_date"::STRING,1,4))
          BETWEEN 2008 AND 2022
    GROUP BY yymm
)
SELECT
    LPAD(LEFT(m.m::STRING,4),4,'0') || '-' ||
    LPAD(RIGHT(m.m::STRING,2),2,'0')           AS "yyyy_mm",
    COALESCE(i.pubs_in_month,0)                AS "pubs_in_month"
FROM months m
LEFT JOIN iot_pubs i
       ON m.m = i.yymm
ORDER BY "yyyy_mm";