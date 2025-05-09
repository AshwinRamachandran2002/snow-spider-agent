SELECT
    ROUND(COUNT(DISTINCT cf."company_id") / 3.0, 4) AS "Average_new_unicorn_companies_per_year_in_top_industry"
FROM "MODERN_DATA"."MODERN_DATA"."COMPANIES_FUNDING" cf
JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_DATES" cd
  ON cf."company_id" = cd."company_id"
JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_INDUSTRIES" ci
  ON cf."company_id" = ci."company_id"
WHERE cf."valuation" >= 1000000000
  AND cd."date_joined" >= '2019-01-01' AND cd."date_joined" <= '2021-12-31'
  AND ci."industry" = (
    SELECT ci2."industry"
    FROM "MODERN_DATA"."MODERN_DATA"."COMPANIES_FUNDING" cf2
    JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_DATES" cd2
      ON cf2."company_id" = cd2."company_id"
    JOIN "MODERN_DATA"."MODERN_DATA"."COMPANIES_INDUSTRIES" ci2
      ON cf2."company_id" = ci2."company_id"
    WHERE cf2."valuation" >= 1000000000
      AND cd2."date_joined" >= '2019-01-01' AND cd2."date_joined" <= '2021-12-31'
    GROUP BY ci2."industry"
    ORDER BY COUNT(DISTINCT cf2."company_id") DESC NULLS LAST
    LIMIT 1
  );