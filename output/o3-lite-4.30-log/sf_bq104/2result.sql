WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS latest_refresh_date
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
latest_week AS (
    SELECT MAX("week") AS latest_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT latest_refresh_date FROM latest_refresh)
),
target_week AS (
    SELECT DATEADD(year, -1, latest_week) AS target_week
    FROM latest_week
),
chosen_week AS (
    SELECT "week"
    FROM (
        SELECT
            DISTINCT "week",
            ROW_NUMBER() OVER (
                ORDER BY ABS(DATEDIFF(day, "week", (SELECT target_week FROM target_week))) ASC,
                         "week" DESC
            ) AS rn
        FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    )
    WHERE rn = 1
),
ranked_terms AS (
    SELECT
        "term",
        ROW_NUMBER() OVER (ORDER BY "rank" ASC, "term" ASC) AS rn
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT "week" FROM chosen_week)
)
SELECT "term" AS rising_search_term
FROM ranked_terms
WHERE rn = 1;