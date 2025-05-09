/* Top-3 Google Trends search terms (ranks 1–3) for each weekday (Mon–Fri)
   between 2024-09-01 and 2024-09-14, determined by refresh_date and
   ordered by newest refresh_date first. */
SELECT
       "refresh_date",
       "week",
       "rank",
       "term",
       "score"
FROM   GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_TERMS"
WHERE  "week" BETWEEN '2024-09-01' AND '2024-09-14'
  AND   DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5   -- Monday=1 … Friday=5
  AND   "rank" IN (1, 2, 3)
ORDER BY
       "refresh_date" DESC NULLS LAST,
       "rank";