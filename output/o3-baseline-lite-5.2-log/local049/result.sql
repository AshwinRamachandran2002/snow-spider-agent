WITH unicorns AS (
    SELECT 
        cf.company_id,
        SUBSTR(cd.date_joined,1,4) AS year,
        ci.industry
    FROM companies_funding     AS cf
    JOIN companies_dates       AS cd USING (company_id)
    JOIN companies_industries  AS ci USING (company_id)
    WHERE cf.valuation >= 1000000000
      AND cd.date_joined >= '2019-01-01'
      AND cd.date_joined <  '2022-01-01'
),
top_industry AS (
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
counts AS (
    SELECT 
        year,
        COUNT(*) AS num_new
    FROM unicorns u
    JOIN top_industry ti ON u.industry = ti.industry
    GROUP BY year
),
years(y) AS (
    VALUES ('2019'), ('2020'), ('2021')
),
year_counts AS (
    SELECT 
        y.y AS year,
        COALESCE(c.num_new, 0) AS num_new
    FROM years y
    LEFT JOIN counts c ON c.year = y.y
)
SELECT 
    AVG(num_new) AS avg_new_unicorns_per_year
FROM year_counts;