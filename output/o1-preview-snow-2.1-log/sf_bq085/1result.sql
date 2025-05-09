SELECT
  s."country_region" AS "Country",
  SUM(s."confirmed") AS "Total_Confirmed_Cases",
  ROUND((SUM(s."confirmed") / p."population") * 100000, 4) AS "Cases_Per_100k"
FROM "COVID19_JHU_WORLD_BANK"."COVID19_JHU_CSSE"."SUMMARY" s
JOIN (
    SELECT
        "country_name",
        MAX("value") AS "population"
    FROM "COVID19_JHU_WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA"
    WHERE "indicator_code" = 'SP.POP.TOTL'
      AND "year" = (
        SELECT MAX("year")
        FROM "COVID19_JHU_WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA"
        WHERE "indicator_code" = 'SP.POP.TOTL'
      )
    GROUP BY "country_name"
) p ON
    CASE s."country_region"
        WHEN 'US' THEN 'United States'
        WHEN 'Iran' THEN 'Iran, Islamic Rep.'
        ELSE s."country_region"
    END = p."country_name"
WHERE s."date" = '2020-04-20' AND s."country_region" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
GROUP BY s."country_region", p."population"
ORDER BY s."country_region";