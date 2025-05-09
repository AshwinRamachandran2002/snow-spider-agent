WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS "max_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (
    SELECT MAX("week") AS "max_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
),
target_week AS (
    SELECT DATEADD(year, -1, (SELECT "max_week" FROM latest_week)) AS "desired_week"
),
closest_week AS (
    SELECT
        "week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
    QUALIFY
        ROW_NUMBER() OVER (
            ORDER BY 
                ABS(DATEDIFF(day, "week", (SELECT "desired_week" FROM target_week))) ASC,
                "week" DESC
        ) = 1
),
ranked_terms AS (
    SELECT
        "term",
        "rank",
        "percent_gain"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "max_refresh_date" FROM latest_refresh)
      AND "week"       = (SELECT "week" FROM closest_week)
)
SELECT
    "term",
    "rank",
    "percent_gain"
FROM ranked_terms
ORDER BY
    "rank" ASC,
    "percent_gain" DESC NULLS LAST,
    "term"
LIMIT 1;