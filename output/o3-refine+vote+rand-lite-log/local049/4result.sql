WITH unicorns AS (
    SELECT 
        cf.company_id,
        cd.date_joined,
        CAST(substr(cd.date_joined, 1, 4) AS INTEGER) AS year,
        ci.industry
    FROM "companies_funding"   AS cf
    JOIN "companies_dates"     AS cd ON cf.company_id = cd.company_id
    JOIN "companies_industries" AS ci ON cf.company_id = ci.company_id
    WHERE cf.valuation >= 1000000000
      AND CAST(substr(cd.date_joined, 1, 4) AS INTEGER) BETWEEN 2019 AND 2021
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
        y.year,
        COALESCE(COUNT(u.company_id), 0) AS unicorns_in_year
    FROM (SELECT 2019 AS year UNION ALL SELECT 2020 UNION ALL SELECT 2021) AS y
    LEFT JOIN unicorns u
        ON y.year = u.year
       AND u.industry = (SELECT industry FROM top_industry)
    GROUP BY y.year
),
average_calc AS (
    SELECT AVG(unicorns_in_year * 1.0) AS avg_per_year
    FROM year_counts
)
SELECT avg_per_year
FROM average_calc;