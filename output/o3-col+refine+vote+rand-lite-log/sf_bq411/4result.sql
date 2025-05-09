SELECT DISTINCT
       "refresh_date",
       "term",
       "rank"
FROM  GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'        -- September 1–14 2024
  AND "rank" IN (1, 2, 3)                                 -- top-three terms
  AND DAYOFWEEK("refresh_date") BETWEEN 2 AND 6           -- Monday-Friday
ORDER BY "refresh_date" DESC NULLS LAST,
         "rank";