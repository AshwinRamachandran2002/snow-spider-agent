/* Identify the single top-ranked rising search term for the week that is
   exactly one year prior to the latest available week, using only the most
   recent refresh_date load */

WITH latest_refresh AS (           -- most-recent data load
    SELECT MAX("refresh_date") AS max_refresh_date
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (                   -- latest week within that load
    SELECT MAX("week") AS max_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT max_refresh_date FROM latest_refresh)
),
target_week AS (                   -- week exactly 52 weeks prior
    SELECT DATEADD(week, -52, max_week) AS week_prior
    FROM latest_week
)
SELECT
    "term",
    "rank",
    "percent_gain",
    "dma_name",
    "week"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE "refresh_date" = (SELECT max_refresh_date FROM latest_refresh)
  AND "week"        = (SELECT week_prior      FROM target_week)
  AND "rank"        = 1                       -- top-ranked rows
ORDER BY "percent_gain" DESC NULLS LAST       -- strongest surge first
LIMIT 1;                                      -- single top-ranked term