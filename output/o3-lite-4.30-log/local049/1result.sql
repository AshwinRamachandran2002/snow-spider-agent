WITH unicorns AS (
    SELECT DISTINCT
        cf.company_id,
        ci.industry,
        substr(cd.date_joined,1,4) AS year
    FROM companies_funding    AS cf
    JOIN companies_dates      AS cd USING (company_id)
    JOIN companies_industries AS ci USING (company_id)
    WHERE cf.valuation >= 1000000000
      AND cd.date_joined BETWEEN '2019-01-01' AND '2021-12-31'
),
top_industry AS (
    SELECT industry
    FROM   unicorns
    GROUP  BY industry
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
yearly_counts AS (
    SELECT year,
           COUNT(company_id) AS cnt
    FROM   unicorns
    WHERE  industry = (SELECT industry FROM top_industry)
    GROUP  BY year
)
SELECT
    (SELECT industry FROM top_industry) AS industry,
    ROUND(AVG(cnt),4)                   AS avg_new_unicorns_per_year
FROM yearly_counts;