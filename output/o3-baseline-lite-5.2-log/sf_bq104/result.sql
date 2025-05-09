WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS "max_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
),
latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
),
target_week AS (
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM latest_week
)
SELECT
    "term",
    "week",
    "rank",
    "percent_gain",
    "dma_name",
    "dma_id",
    "refresh_date"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
WHERE
    "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
    AND "week"     = (SELECT "target_week" FROM target_week)
ORDER BY
    "rank" ASC NULLS LAST,
    "percent_gain" DESC NULLS LAST,
    "term" ASC
LIMIT 1;