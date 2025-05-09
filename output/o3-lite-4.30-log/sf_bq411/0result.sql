SELECT DISTINCT
       "refresh_date",
       "rank",
       "term" AS "top_term"
FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
  AND "rank" IN (1, 2, 3)
ORDER BY "refresh_date" DESC NULLS LAST,
         "rank" ASC;