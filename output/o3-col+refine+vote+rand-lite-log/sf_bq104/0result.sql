/* Top-ranked rising search term for the week one-year prior to the latest week (using the most-recent refresh date) */
WITH
latest_refresh AS (          -- most-recent refresh date in the table
    SELECT MAX("refresh_date") AS "max_refresh_date"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
),
latest_week AS (             -- latest week for that refresh date
    SELECT MAX("week") AS "latest_week"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
),
target_week AS (             -- stored week closest to “exactly one-year-prior”
    SELECT  "week"
    FROM   (SELECT DISTINCT "week"
            FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS") w
           CROSS JOIN latest_week lw
    ORDER BY ABS(DATEDIFF(day, w."week",
                          DATEADD(year, -1, lw."latest_week"))) ASC
    LIMIT 1
),
best_rank AS (               -- best (minimum) rank for that target week
    SELECT MIN("rank") AS "min_rank"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
      AND "week" = (SELECT "week" FROM target_week)
)
SELECT "term",
       "rank"
FROM   "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
WHERE  "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
  AND  "week" = (SELECT "week" FROM target_week)
  AND  "rank" = (SELECT "min_rank" FROM best_rank)
ORDER BY "term"            -- tie-break by term alphabetically, if any
LIMIT 1;