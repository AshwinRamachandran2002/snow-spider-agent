/* Identify the top-ranked rising search term(s) for the week exactly
   one year (52 weeks) before the latest available week in the data */
WITH latest_refresh AS (   -- most-recent refresh_date
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (           -- latest week tied to that refresh_date
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "latest_refresh_date" FROM latest_refresh)
),
yr_prior_week AS (         -- week exactly 52 weeks earlier
    SELECT DATEADD(week, -52, "latest_week") AS "one_year_prior_week"
    FROM latest_week
),
best_rank AS (             -- minimum (best) rank in that prior week
    SELECT MIN("rank") AS "top_rank"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT "one_year_prior_week" FROM yr_prior_week)
)
SELECT DISTINCT            -- top-ranked rising term(s)
       "term"              AS "top_rising_term",
       "rank",
       "week"
FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE  "week" = (SELECT "one_year_prior_week" FROM yr_prior_week)
  AND  "rank" = (SELECT "top_rank" FROM best_rank)
ORDER BY "term";