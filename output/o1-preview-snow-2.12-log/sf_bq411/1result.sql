SELECT "refresh_date", "term", "rank"
FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE "rank" IN (1, 2, 3)
  AND "refresh_date" >= '2024-09-19'
  AND EXTRACT(DAYOFWEEK FROM "refresh_date") BETWEEN 2 AND 6
ORDER BY "refresh_date" DESC, "rank" ASC
LIMIT 30;