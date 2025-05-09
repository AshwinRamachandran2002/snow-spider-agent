WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS max_refresh_date
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (
    SELECT MAX("week") AS max_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT max_refresh_date FROM latest_refresh)
),
target_week AS (
    SELECT DATEADD(week, -52, max_week) AS week_1yr_prior
    FROM latest_week
),
min_rank AS (
    SELECT MIN("rank") AS top_rank
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT max_refresh_date FROM latest_refresh)
      AND "week" = (SELECT week_1yr_prior FROM target_week)
),
candidate_terms AS (
    SELECT "term"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT max_refresh_date FROM latest_refresh)
      AND "week" = (SELECT week_1yr_prior FROM target_week)
      AND "rank" = (SELECT top_rank FROM min_rank)
)
SELECT "term" AS rising_search_term
FROM candidate_terms
GROUP BY "term"
ORDER BY COUNT(*) DESC, "term" ASC
LIMIT 1;