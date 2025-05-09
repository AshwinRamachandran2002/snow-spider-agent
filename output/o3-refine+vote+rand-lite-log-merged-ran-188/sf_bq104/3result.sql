/* Return the single highest-ranked rising search term for the
   stored week that is closest to exactly one-year-ago from the
   latest available week (based on the newest refresh). */

WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS max_refresh
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (
    SELECT MAX("week") AS latest_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT max_refresh FROM latest_refresh)
),
target_day AS (
    SELECT DATEADD(year, -1, latest_week) AS target_date
    FROM latest_week
),
closest_week AS (
    SELECT "week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS, target_day
    ORDER BY ABS(DATEDIFF(day, "week", target_day.target_date)) ASC
    LIMIT 1
),
best_rank AS (
    SELECT MIN("rank") AS min_rank
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT "week" FROM closest_week)
)
SELECT "term",
       "rank",
       "week"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE "week" = (SELECT "week" FROM closest_week)
  AND "rank" = (SELECT min_rank FROM best_rank)
ORDER BY "percent_gain" DESC NULLS LAST
LIMIT 1;