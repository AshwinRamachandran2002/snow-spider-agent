SELECT "country_region" AS "Country", 
       ROUND((SUM("recovered") / SUM("confirmed")) * 100, 4) AS "Recovery_Rate"
FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COMPATIBILITY_VIEW
WHERE "date" = '2020-05-10'
  AND "confirmed" > 0
  AND "recovered" > 0
GROUP BY "country_region"
HAVING SUM("confirmed") > 50000
   AND SUM("recovered") <= SUM("confirmed")
ORDER BY "Recovery_Rate" DESC
LIMIT 3;