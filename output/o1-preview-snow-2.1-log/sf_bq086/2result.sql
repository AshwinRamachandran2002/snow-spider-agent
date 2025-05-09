SELECT "country_name", "cumulative_confirmed", "population",
       ROUND(("cumulative_confirmed" * 100.0) / "population", 4) AS "percentage_confirmed"
FROM "COVID19_OPEN_WORLD_BANK"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"
WHERE "date" = '2020-06-30' AND "aggregation_level" = 0
      AND "population" IS NOT NULL AND "population" > 0
      AND "cumulative_confirmed" IS NOT NULL;