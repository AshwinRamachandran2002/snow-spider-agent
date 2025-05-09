/* Top-ranked rising search term for the week exactly one year (52 weeks)
   before the latest week in the dataset */
WITH latest_week AS (
    SELECT MAX("week") AS latest_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
target_week AS (
    SELECT DATEADD(week, -52, latest_week) AS target_week
    FROM latest_week
),
best_rank AS (
    SELECT MIN("rank") AS best_rank
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT target_week FROM target_week)
)
SELECT DISTINCT
       "term",
       "rank"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE "week" = (SELECT target_week FROM target_week)
  AND "rank" = (SELECT best_rank FROM best_rank)
ORDER BY "term" ASC;