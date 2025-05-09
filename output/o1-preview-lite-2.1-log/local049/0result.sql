SELECT ROUND(AVG("yearly_count"), 4) AS "average_number_of_new_unicorns_per_year"
FROM (
  SELECT SUBSTR(cd."date_joined", 1, 4) AS "year", COUNT(*) AS "yearly_count"
  FROM "companies_funding" AS cf
  JOIN "companies_dates" AS cd ON cf."company_id" = cd."company_id"
  JOIN "companies_industries" AS ci ON cf."company_id" = ci."company_id"
  WHERE cf."valuation" >= 1000000000
    AND SUBSTR(cd."date_joined", 1, 4) BETWEEN '2019' AND '2021'
    AND ci."industry" = 'Fintech'
  GROUP BY "year"
);