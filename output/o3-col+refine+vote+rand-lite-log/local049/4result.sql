WITH unicorns AS (                       -- unicorns founded 2019-2021
    SELECT i.industry
    FROM   companies_funding      AS f
    JOIN   companies_dates        AS d ON f.company_id = d.company_id
    JOIN   companies_industries   AS i ON f.company_id = i.company_id
    WHERE  f.valuation >= 1000000000
      AND  substr(d.date_joined, 1, 4) IN ('2019','2020','2021')
),
top_industry AS (                       -- industry with the most such unicorns
    SELECT industry,
           COUNT(*) AS total_unicorns
    FROM   unicorns
    GROUP  BY industry
    ORDER  BY total_unicorns DESC
    LIMIT  1
)
SELECT industry,
       ROUND(1.0 * total_unicorns / 3, 2) AS avg_unicorns_per_year
FROM   top_industry;