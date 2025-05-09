WITH top_industry AS (
    SELECT ci."industry"
    FROM "companies_industries" ci
    JOIN "companies_dates" cd ON ci."company_id" = cd."company_id"
    JOIN "companies_funding" cf ON ci."company_id" = cf."company_id"
    WHERE cf."valuation" >= 1000000000
      AND cd."date_joined" BETWEEN '2019-01-01' AND '2021-12-31'
    GROUP BY ci."industry"
    ORDER BY COUNT(DISTINCT ci."company_id") DESC
    LIMIT 1
)
SELECT ROUND(CAST(COUNT(DISTINCT ci."company_id") AS FLOAT) / 3.0, 4) AS average_number_of_new_unicorns_per_year
FROM "companies_industries" ci
JOIN "companies_dates" cd ON ci."company_id" = cd."company_id"
JOIN "companies_funding" cf ON ci."company_id" = cf."company_id"
WHERE cf."valuation" >= 1000000000
  AND cd."date_joined" BETWEEN '2019-01-01' AND '2021-12-31'
  AND ci."industry" = (SELECT "industry" FROM top_industry);