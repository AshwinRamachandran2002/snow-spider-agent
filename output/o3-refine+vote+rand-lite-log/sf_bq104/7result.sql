WITH most_recent_snapshot AS (          -- rows from latest refresh
    SELECT *
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (
        SELECT MAX("refresh_date")
        FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    )
),
latest_week AS (                        -- latest week in that snapshot
    SELECT MAX("week") AS "latest_week"
    FROM   most_recent_snapshot
),
target_week AS (                        -- exactly 52 weeks earlier
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM   latest_week
)
SELECT
    "term",
    "rank",
    "week"
FROM   most_recent_snapshot
WHERE  "week" = (SELECT "target_week" FROM target_week)
ORDER BY
    "rank" ASC,
    "percent_gain" DESC NULLS LAST
LIMIT 1;