/* Top-three (ranks 1-3) Google Trends search terms whose
   refresh_date falls on Monday-through-Friday between
   2024-09-01 and 2024-09-14, ordered by latest refresh_date */
SELECT DISTINCT
       "refresh_date",
       "week",
       "term",
       "rank"
FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE  "week" BETWEEN '2024-09-01' AND '2024-09-14'
  AND  "rank" IN (1, 2, 3)
  AND  DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5   -- 1=Mon … 5=Fri
ORDER BY
       "refresh_date" DESC NULLS LAST,
       "rank",
       "term";