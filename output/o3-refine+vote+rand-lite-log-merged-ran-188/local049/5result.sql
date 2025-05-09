WITH unicorns AS (
    SELECT cf.company_id,
           ci.industry,
           SUBSTR(cd.date_joined, 1, 4) AS yr
    FROM companies_funding      AS cf
    JOIN companies_dates        AS cd ON cd.company_id = cf.company_id
    JOIN companies_industries   AS ci ON ci.company_id = cf.company_id
    WHERE cf.valuation >= 1000000000                    -- unicorns
      AND SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (                     -- industry with most new unicorns 2019‑2021
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (                    -- per‑year counts in that industry
    SELECT yr,
           COUNT(*) AS cnt
    FROM unicorns
    WHERE industry = (SELECT industry FROM top_industry)
    GROUP BY yr
)
SELECT AVG(cnt) AS avg_new_unicorns_per_year
FROM yearly_counts;