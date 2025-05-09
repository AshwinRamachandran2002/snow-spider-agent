/* Top-ranked rising search term for the week exactly one year before the latest week */
WITH
latest_refresh AS (
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
),
latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "refresh_date" = (SELECT "latest_refresh_date" FROM latest_refresh)
),
target_week AS (
    /* closest recorded week on or before the date exactly one year prior */
    SELECT MAX("week") AS "target_week"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "week" <= DATEADD(year, -1, (SELECT "latest_week" FROM latest_week))
),
best_rank AS (
    SELECT MIN("rank") AS "top_rank"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
    WHERE "week" = (SELECT "target_week" FROM target_week)
)
SELECT
    "term",
    "rank",
    "week",
    "dma_name",
    "percent_gain",
    "score"
FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
WHERE "week" = (SELECT "target_week" FROM target_week)
  AND "rank" = (SELECT "top_rank" FROM best_rank)
ORDER BY "term";