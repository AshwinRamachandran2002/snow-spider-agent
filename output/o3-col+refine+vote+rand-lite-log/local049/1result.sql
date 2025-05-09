WITH top_industry AS (
    SELECT ci."industry"
    FROM   "companies_funding" AS cf
    JOIN   "companies_industries" AS ci
           ON ci."company_id" = cf."company_id"
    WHERE  cf."valuation" >= 1000000000           -- unicorns
    GROUP BY ci."industry"
    ORDER BY COUNT(*) DESC                        -- most unicorn-rich industry
    LIMIT 1
),
yearly_counts AS (
    SELECT SUBSTR(cd."date_joined", 1, 4) AS "year",
           COUNT(DISTINCT cd."company_id") AS "new_unicorns"
    FROM   "companies_funding"   AS cf
    JOIN   "companies_dates"     AS cd ON cd."company_id" = cf."company_id"
    JOIN   "companies_industries" AS ci ON ci."company_id" = cf."company_id"
    WHERE  cf."valuation" >= 1000000000
      AND  ci."industry" = (SELECT "industry" FROM top_industry)
      AND  SUBSTR(cd."date_joined", 1, 4) BETWEEN '2019' AND '2021'
    GROUP BY "year"
)
SELECT AVG("new_unicorns") AS "avg_new_unicorns_per_year"
FROM   yearly_counts;