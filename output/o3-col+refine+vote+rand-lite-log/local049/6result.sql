WITH unicorns AS (                          -- companies valued ≥ $1 B
    SELECT company_id
    FROM companies_funding
    WHERE valuation >= 1000000000
),
unicorns_2019_2021 AS (                     -- those founded (joined) 2019-2021
    SELECT u.company_id
    FROM unicorns u
    JOIN companies_dates cd
          ON cd.company_id = u.company_id
    WHERE SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (                           -- industry with most such unicorns
    SELECT ci.industry
    FROM companies_industries ci
    JOIN unicorns_2019_2021 u
          ON u.company_id = ci.company_id
    GROUP BY ci.industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_totals AS (                          -- yearly counts in that industry
    SELECT SUBSTR(cd.date_joined, 1, 4) AS year_joined,
           COUNT(*)                       AS new_unicorns
    FROM companies_dates      cd
    JOIN companies_industries ci  ON ci.company_id = cd.company_id
    JOIN top_industry         ti  ON ti.industry   = ci.industry
    JOIN unicorns             u   ON u.company_id  = cd.company_id
    WHERE SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
    GROUP BY SUBSTR(cd.date_joined, 1, 4)
)
SELECT ti.industry                                AS top_industry,
       ROUND(AVG(new_unicorns), 4)                AS avg_new_unicorns_per_year
FROM yearly_totals
CROSS JOIN top_industry ti;