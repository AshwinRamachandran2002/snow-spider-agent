/*--------------------------------------------------------------
  Return the #1-ranked rising search term(s) for the week that is
  closest (±14 days) to exactly one year before the latest week
  in any rising-terms table, using the freshest snapshot for that
  week.  Works across both U.S. and International datasets.
--------------------------------------------------------------*/
WITH all_rising AS (          -- combine U.S. + International rising terms
    SELECT 'US'   AS "source",
           "term",
           "rank",
           "percent_gain",
           "week",
           "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    UNION ALL
    SELECT 'INTL' AS "source",
           "term",
           "rank",
           "percent_gain",
           "week",
           "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.INTERNATIONAL_TOP_RISING_TERMS
),
latest_wk AS (                -- latest available week
    SELECT MAX("week") AS "latest_week"
    FROM all_rising
),
target_dt AS (                -- exactly one year before that week
    SELECT DATEADD(year, -1, "latest_week") AS "tgt_date"
    FROM latest_wk
),
candidates AS (               -- weeks within ±14 days of the target date
    SELECT DISTINCT
           "week",
           ABS(DATEDIFF(day, "week", (SELECT "tgt_date" FROM target_dt))) AS diff_days
    FROM all_rising
    WHERE ABS(DATEDIFF(day, "week", (SELECT "tgt_date" FROM target_dt))) <= 14
),
chosen_wk AS (                -- pick the closest (newest if tie)
    SELECT "week"
    FROM candidates
    ORDER BY diff_days ASC, "week" DESC
    LIMIT 1
),
fresh_snap AS (               -- freshest refresh_date for that week
    SELECT MAX("refresh_date") AS "freshest_refresh"
    FROM all_rising
    WHERE "week" = (SELECT "week" FROM chosen_wk)
)
SELECT
    "term",
    "rank",
    "week",
    "refresh_date",
    "source"
FROM all_rising
WHERE "week"         = (SELECT "week"            FROM chosen_wk)
  AND "refresh_date" = (SELECT "freshest_refresh" FROM fresh_snap)
  AND "rank" = 1;