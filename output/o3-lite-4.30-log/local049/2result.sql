WITH top_industry AS (
    SELECT ci.industry
    FROM companies_funding cf
    JOIN companies_industries ci ON cf.company_id = ci.company_id
    JOIN companies_dates cd ON cf.company_id = cd.company_id
    WHERE cf.valuation >= 1000000000
      AND substr(cd.date_joined,1,4) BETWEEN '2019' AND '2021'
    GROUP BY ci.industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    SELECT substr(cd.date_joined,1,4) AS yr,
           COUNT(*)                   AS cnt
    FROM companies_funding cf
    JOIN companies_industries ci ON cf.company_id = ci.company_id
    JOIN companies_dates cd ON cf.company_id = cd.company_id
    JOIN top_industry ti ON ci.industry = ti.industry
    WHERE cf.valuation >= 1000000000
      AND substr(cd.date_joined,1,4) BETWEEN '2019' AND '2021'
    GROUP BY yr
)
SELECT (SELECT industry FROM top_industry) AS industry,
       ROUND(AVG(cnt),4)                   AS avg_new_unicorns_per_year
FROM yearly_counts;