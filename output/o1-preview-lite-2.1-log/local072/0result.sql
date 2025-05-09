SELECT
  CAST(SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS "proportion_of_entries_from_capital"
FROM "cities"
WHERE "country_code_2" = 'ir'
  AND "insert_date" BETWEEN '2022-01-20' AND '2022-01-22';