WITH CountryMapping AS (
  SELECT 'US' AS "country_region", 'United States' AS "country_name"
  UNION ALL
  SELECT 'China' AS "country_region", 'China' AS "country_name"
  UNION ALL
  SELECT 'France' AS "country_region", 'France' AS "country_name"
  UNION ALL
  SELECT 'Germany' AS "country_region", 'Germany' AS "country_name"
  UNION ALL
  SELECT 'Iran' AS "country_region", 'Iran' AS "country_name"
  UNION ALL
  SELECT 'Italy' AS "country_region", 'Italy' AS "country_name"
  UNION ALL
  SELECT 'Spain' AS "country_region", 'Spain' AS "country_name"
),
CovidData AS (
  SELECT s."country_region", SUM(s."confirmed") AS "Total_Confirmed_Cases"
  FROM "COVID19_JHU_WORLD_BANK"."COVID19_JHU_CSSE"."SUMMARY" s
  WHERE s."date" = '2020-04-20' AND s."country_region" IN ('US', 'China', 'France', 'Germany', 'Iran', 'Italy', 'Spain')
  GROUP BY s."country_region"
),
PopulationData AS (
  SELECT 
    CASE WHEN id."country_name" = 'Iran, Islamic Rep.' THEN 'Iran' ELSE id."country_name" END AS "country_name",
    id."value" AS "population"
  FROM "COVID19_JHU_WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" id
  WHERE id."indicator_code" = 'SP.POP.TOTL' 
    AND id."year" = 2019
    AND id."country_name" IN ('United States', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran, Islamic Rep.')
)
SELECT cm."country_name" AS "Country",
       cd."Total_Confirmed_Cases",
       ROUND( (cd."Total_Confirmed_Cases" / pd."population") * 100000, 4) AS "Cases_Per_100k"
FROM CovidData cd
INNER JOIN CountryMapping cm ON cd."country_region" = cm."country_region"
INNER JOIN PopulationData pd ON cm."country_name" = pd."country_name"
ORDER BY cm."country_name";