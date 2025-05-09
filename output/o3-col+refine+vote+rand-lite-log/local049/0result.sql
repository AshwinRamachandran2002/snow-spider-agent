WITH unicorns AS (
    SELECT cf.company_id,
           ci.industry,
           SUBSTR(cd.date_joined, 1, 4) AS year_joined
    FROM   companies_funding    AS cf
    JOIN   companies_dates      AS cd ON cf.company_id = cd.company_id
    JOIN   companies_industries AS ci ON cf.company_id = ci.company_id
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
    SELECT year_joined,
           COUNT(*) AS yearly_count
    FROM   unicorns
    WHERE  industry = (SELECT industry FROM top_industry)
    GROUP  BY year_joined
)
SELECT AVG(yearly_count) AS avg_new_unicorns_per_year
FROM   yearly_counts;