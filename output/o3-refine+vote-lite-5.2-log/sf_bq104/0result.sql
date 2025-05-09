WITH latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
target_week AS (
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM latest_week
)
SELECT
    "term",
    "rank",
    "week"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
JOIN target_week tw
  ON tr."week" = tw."target_week"
ORDER BY
    "rank" ASC,
    "term" ASC
LIMIT 1;