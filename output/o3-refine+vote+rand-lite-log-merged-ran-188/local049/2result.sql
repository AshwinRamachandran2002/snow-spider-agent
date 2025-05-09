WITH unicorns AS (
    SELECT
        cf.company_id,
        cf.valuation,
        substr(cd.date_joined, 1, 4) AS join_year,
        ci.industry
    FROM companies_funding  AS cf
    JOIN companies_dates    AS cd ON cf.company_id = cd.company_id
    JOIN companies_industries AS ci ON cf.company_id = ci.company_id
    WHERE cf.valuation >= 1000000000          -- unicorn threshold
),
top_industry AS (
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
year_counts AS (
    SELECT
        join_year,
        COUNT(DISTINCT company_id) AS cnt
    FROM unicorns
    WHERE join_year IN ('2019','2020','2021')
      AND industry = (SELECT industry FROM top_industry)
    GROUP BY join_year
)
SELECT AVG(cnt) AS avg_new_unicorns_per_year
FROM year_counts;