WITH month_series AS (                                                          -- all months 2008‑01 to 2022‑12
    SELECT DATEADD(month,
                   seq4(),
                   DATE_TRUNC('month', TO_DATE('2008-01-01'))) AS month_start
    FROM   TABLE(GENERATOR(ROWCOUNT => 180))                                    -- 15 years * 12 = 180 months
),

iot_publications AS (                                                           -- US filings whose abstract says "internet of things"
    SELECT DISTINCT
           p."publication_number",
           DATE_TRUNC('month',
                      TO_DATE(TO_VARCHAR(p."filing_date"), 'YYYYMMDD')) AS filing_month
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."abstract_localized") f
    WHERE p."country_code" = 'US'
      AND p."filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER(f.value:"text"::STRING) LIKE '%internet of things%'
),

monthly_counts AS (                                                             -- count per filing month
    SELECT filing_month AS month_start,
           COUNT(*)     AS publication_count
    FROM   iot_publications
    GROUP  BY filing_month
)

SELECT m.month_start,
       COALESCE(c.publication_count, 0) AS publication_count
FROM   month_series      m
LEFT   JOIN monthly_counts c
       ON m.month_start = c.month_start
ORDER  BY m.month_start;