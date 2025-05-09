SELECT s."country_region",
       SUM(s."confirmed") AS "Total_Confirmed_Cases",
       p."value" AS "Population",
       ROUND((SUM(s."confirmed") / p."value") * 100000, 4) AS "Cases_Per_100k"
FROM "COVID19_JHU_WORLD_BANK"."COVID19_JHU_CSSE"."SUMMARY" AS s
JOIN "COVID19_JHU_WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" AS p
  ON (
    CASE
      WHEN s."country_region" = 'US' THEN 'United States'
      WHEN s."country_region" = 'Iran' THEN 'Iran, Islamic Rep.'
      ELSE s."country_region"
    END
  ) = p."country_name"
WHERE s."date" = '2020-04-20'
  AND p."indicator_code" = 'SP.POP.TOTL'
  AND p."year" = 2020
  AND s."country_region" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
GROUP BY s."country_region", p."value";