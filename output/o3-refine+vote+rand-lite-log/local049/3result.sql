WITH unicorns AS (                         -- 1. identify unicorns (valuation ≥ $1 B)
    SELECT company_id
    FROM companies_funding
    WHERE valuation >= 1000000000
),
new_unicorns AS (                          -- 2. keep only those that became unicorns 2019‑2021
    SELECT u.company_id,
           date(companies_dates.date_joined)       AS joined_date,
           companies_industries.industry
    FROM unicorns                AS u
    JOIN companies_dates         ON u.company_id = companies_dates.company_id
    JOIN companies_industries    ON u.company_id = companies_industries.company_id
    WHERE joined_date BETWEEN '2019-01-01' AND '2021-12-31'
),
top_industry AS (                          -- 3. industry with the most new unicorns
    SELECT industry
    FROM new_unicorns
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (                         -- 4. counts per year for that industry
    SELECT strftime('%Y', joined_date) AS yr,
           COUNT(*)                    AS cnt
    FROM new_unicorns
    WHERE industry = (SELECT industry FROM top_industry)
    GROUP BY yr
),
totals AS (                                -- 5. total new unicorns in 2019‑2021
    SELECT SUM(cnt) AS total_unicorns
    FROM yearly_counts
)
-- 6. average number per year (divide by 3 years: 2019, 2020, 2021)
SELECT ROUND(CAST(total_unicorns AS REAL) / 3.0, 4) AS avg_new_unicorns_per_year
FROM totals;