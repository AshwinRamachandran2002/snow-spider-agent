WITH iot_pubs AS (        -- U.S. applications whose abstract mentions “internet of things”
    SELECT DISTINCT
           p."publication_number",
           TO_DATE(p."filing_date"::STRING , 'YYYYMMDD') AS filing_dt
    FROM  PATENTS.PATENTS.PUBLICATIONS p,
          LATERAL FLATTEN(input => p."abstract_localized") al
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER(al.value:"text"::STRING) LIKE '%internet of things%'
),
months AS (                -- every month from Jan-2008 to Dec-2022
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), TO_DATE('2008-01-01'))) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))                      -- 15 years * 12 months
),
counts AS (                -- monthly filing counts for IoT publications
    SELECT DATE_TRUNC('month', filing_dt) AS month_start,
           COUNT(DISTINCT "publication_number")                AS n
    FROM   iot_pubs
    GROUP  BY month_start
)
SELECT
    TO_CHAR(m.month_start, 'YYYY')           AS year,
    TO_CHAR(m.month_start, 'MM')             AS month,
    COALESCE(c.n, 0)                         AS iot_publications_filed
FROM   months m
LEFT   JOIN counts c ON m.month_start = c.month_start
ORDER  BY m.month_start;