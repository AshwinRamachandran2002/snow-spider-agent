SELECT "country_name" AS "Country",
       ROUND(("cumulative_recovered" / "cumulative_confirmed") * 100, 4) AS "Recovery_Rate"
FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
WHERE "date" = '2020-05-10'
  AND "aggregation_level" = 0
  AND "cumulative_confirmed" >= 50000
  AND "cumulative_recovered" IS NOT NULL 
  AND "cumulative_recovered" > 0
  AND "cumulative_recovered" <= "cumulative_confirmed"
ORDER BY "Recovery_Rate" DESC NULLS LAST
LIMIT 3;