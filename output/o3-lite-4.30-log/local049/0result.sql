WITH unicorns AS (
    SELECT DISTINCT
        f.company_id,
        SUBSTR(d.date_joined, 1, 4) AS yr,
        i.industry
    FROM companies_funding    AS f
    JOIN companies_dates      AS d ON d.company_id = f.company_id
    JOIN companies_industries AS i ON i.company_id = f.company_id
    WHERE f.valuation >= 1000000000
      AND SUBSTR(d.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(DISTINCT company_id) DESC
    LIMIT 1
),
year_counts AS (
    SELECT
        yr,
        COUNT(DISTINCT company_id) AS cnt
    FROM unicorns
    WHERE industry = (SELECT industry FROM top_industry)
    GROUP BY yr
)
SELECT
    (SELECT industry FROM top_industry) AS industry,
    ROUND(AVG(cnt), 4)                  AS avg_new_unicorns_per_year
FROM year_counts;