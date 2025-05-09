WITH unicorns AS (
    SELECT cf.company_id,
           ci.industry,
           SUBSTR(cd.date_joined, 1, 4) AS yr
    FROM   companies_funding     AS cf
    JOIN   companies_dates       AS cd USING (company_id)
    JOIN   companies_industries  AS ci USING (company_id)
    WHERE  cf.valuation >= 1000000000
      AND  SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    SELECT industry
    FROM   unicorns
    GROUP  BY industry
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    SELECT yr,
           COUNT(*) AS new_unicorns
    FROM   unicorns
    WHERE  industry = (SELECT industry FROM top_industry)
    GROUP  BY yr
)
SELECT (SELECT industry FROM top_industry) AS industry,
       AVG(new_unicorns)                   AS avg_new_unicorns_per_year
FROM   yearly_counts;