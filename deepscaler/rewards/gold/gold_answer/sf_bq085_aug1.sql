-- Task: For the United States, France, China, Italy, Spain, Germany, and Iran, provide the total number of confirmed COVID-19 cases as of April 20, 2020.
SELECT s."country_region",
       SUM(s."confirmed") AS "Total_Confirmed_Cases"
FROM "COVID19_JHU_WORLD_BANK"."COVID19_JHU_CSSE"."SUMMARY" AS s
WHERE s."date" = '2020-04-20'
  AND s."country_region" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
GROUP BY s."country_region";