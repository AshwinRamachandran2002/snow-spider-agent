-- Task: Based on the most recent refresh date, identify the rising search terms for the week that is exactly one year prior to the latest week in the dataset.
WITH LatestWeek AS (
    SELECT
        DATEADD(WEEK, -52, MAX("week")) AS "last_year_week"
    FROM
        GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
LatestRefreshDate AS (
    SELECT
        MAX("refresh_date") AS "latest_refresh_date"
    FROM
        GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
)
SELECT
    "term",
    "rank",
    "score"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE
    "week" = (SELECT "last_year_week" FROM LatestWeek)
    AND "refresh_date" = (SELECT "latest_refresh_date" FROM LatestRefreshDate)
ORDER BY
    "rank"
LIMIT 100;