SELECT ROUND(
  (SELECT COUNT(*) * 1.0
   FROM "cities" ci
   JOIN "cities_countries" c ON ci."country_code_2" = c."country_code_2"
   WHERE c."country_name" = 'iran' AND ci."capital" = 1 AND ci."insert_date" BETWEEN '2022-01-20' AND '2022-01-22') /
  (SELECT COUNT(*)
   FROM "cities" ci2
   JOIN "cities_countries" c2 ON ci2."country_code_2" = c2."country_code_2"
   WHERE c2."country_name" = 'iran' AND ci2."insert_date" BETWEEN '2022-01-20' AND '2022-01-22'), 4) AS "proportion_of_entries_from_capital";