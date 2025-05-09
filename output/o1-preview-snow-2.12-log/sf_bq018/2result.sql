SELECT TO_CHAR("date", 'MM-DD') AS "Date"
FROM "COVID19_OPEN_DATA"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"
WHERE "country_code" = 'US'
  AND "date" BETWEEN '2020-03-01' AND '2020-04-30'
  AND "aggregation_level" = 0
ORDER BY ("new_confirmed" / NULLIF("cumulative_confirmed", 0)) * 100 DESC NULLS LAST
LIMIT 1;