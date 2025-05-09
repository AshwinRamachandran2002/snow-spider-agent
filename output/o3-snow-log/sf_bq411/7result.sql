SELECT DISTINCT
       "refresh_date",
       "rank",
       "term"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'  -- weeks of interest
  AND DAYOFWEEK("refresh_date") BETWEEN 1 AND 5       -- Monday (1) through Friday (5)
  AND "rank" IN (1, 2, 3)                             -- top-three ranks
ORDER BY
       "refresh_date" DESC NULLS LAST,
       "rank" ASC;