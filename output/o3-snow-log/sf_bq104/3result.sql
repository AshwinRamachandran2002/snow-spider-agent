/* find the latest load, locate the week closest to one-year prior,
   then return the single highest-ranked rising term from that week */
WITH latest_refresh AS (       -- most-recent data load
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
), latest_week AS (            -- newest week within that load
    SELECT MAX("week") AS "latest_week"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "refresh_date" = (SELECT "latest_refresh_date" FROM latest_refresh)
), target_date AS (            -- “one-year-ago” reference date
    SELECT DATEADD(year, -1, "latest_week") AS "target_date"
    FROM   latest_week
), closest_week AS (           -- actual stored week closest to that date
    SELECT "week"
    FROM   "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS",
           target_date,
           latest_refresh
    WHERE  "refresh_date" = latest_refresh."latest_refresh_date"
    ORDER  BY ABS(DATEDIFF(day, "week", target_date."target_date")) ASC,
              "week" DESC
    LIMIT  1
), best_rank AS (              -- lowest (best) rank in that week
    SELECT MIN("rank") AS "best_rank"
    FROM   "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE  "refresh_date" = (SELECT "latest_refresh_date" FROM latest_refresh)
      AND  "week"         = (SELECT "week" FROM closest_week)
)
SELECT
    "term",
    "rank",
    "percent_gain",
    "dma_name",
    "dma_id",
    "week"
FROM   "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
WHERE  "refresh_date" = (SELECT "latest_refresh_date" FROM latest_refresh)
  AND  "week"         = (SELECT "week" FROM closest_week)
  AND  "rank"         = (SELECT "best_rank" FROM best_rank)
ORDER  BY "percent_gain" DESC NULLS LAST, "term"
LIMIT  1;