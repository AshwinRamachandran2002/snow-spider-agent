SELECT ROUND(CAST(COUNT(DISTINCT cd."company_id") AS FLOAT) / 3, 4) AS "average_number_of_new_unicorns_per_year"
FROM "companies_dates" cd
JOIN "companies_industries" ci ON cd."company_id" = ci."company_id"
JOIN "companies_funding" cf ON cd."company_id" = cf."company_id"
WHERE cd."date_joined" BETWEEN '2019-01-01' AND '2021-12-31'
  AND cf."valuation" >= 1000000000
  AND ci."industry" = (
    SELECT ci2."industry"
    FROM "companies_dates" cd2
    JOIN "companies_industries" ci2 ON cd2."company_id" = ci2."company_id"
    JOIN "companies_funding" cf2 ON cd2."company_id" = cf2."company_id"
    WHERE cd2."date_joined" BETWEEN '2019-01-01' AND '2021-12-31'
      AND cf2."valuation" >= 1000000000
    GROUP BY ci2."industry"
    ORDER BY COUNT(DISTINCT cd2."company_id") DESC
    LIMIT 1
  );