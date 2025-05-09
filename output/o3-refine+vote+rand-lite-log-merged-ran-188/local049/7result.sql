WITH unicorns AS (
    SELECT
        cf.company_id,
        ci.industry,
        CAST(substr(cd.date_joined, 1, 4) AS INTEGER) AS yr
    FROM companies_funding      cf
    JOIN companies_dates        cd USING (company_id)
    JOIN companies_industries   ci USING (company_id)
    WHERE cf.valuation >= 1000000000          -- unicorn threshold
      AND CAST(substr(cd.date_joined,1,4) AS INTEGER) BETWEEN 2019 AND 2021
),
top_industry AS (                               -- industry with the most new unicorns
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(DISTINCT company_id) DESC
    LIMIT 1
),
yearly_counts AS (                              -- unicorns per year for that industry
    SELECT
        yr,
        COUNT(DISTINCT company_id) AS cnt
    FROM unicorns
    WHERE industry = (SELECT industry FROM top_industry)
    GROUP BY yr
),
all_years AS (                                  -- ensure years with zero counts are included
    SELECT 2019 AS yr UNION ALL
    SELECT 2020 UNION ALL
    SELECT 2021
),
filled_counts AS (
    SELECT
        a.yr,
        COALESCE(y.cnt, 0) AS cnt
    FROM all_years a
    LEFT JOIN yearly_counts y USING (yr)
)
SELECT ROUND(AVG(cnt), 4) AS avg_new_unicorns_per_year
FROM filled_counts;