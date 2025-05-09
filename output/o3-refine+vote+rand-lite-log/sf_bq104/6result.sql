WITH latest_week AS (
    /* Most recent week in the whole table */
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
target_week AS (
    /* Exactly 52 weeks (1 year) before that latest week */
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM latest_week
),
latest_refresh_for_target AS (
    /* Latest refresh date that contains data for the target week */
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN target_week tw
      ON tr."week" = tw."target_week"
),
target_rows AS (
    /* Rows for the target week taken from its latest refresh */
    SELECT tr."term",
           tr."rank",
           tr."week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN target_week tw
      ON tr."week" = tw."target_week"
    JOIN latest_refresh_for_target lr
      ON tr."refresh_date" = lr."latest_refresh_date"
),
ordered AS (
    /* Rank by smallest (best) rank, tie‑break alphabetically */
    SELECT "term",
           "rank",
           "week",
           ROW_NUMBER() OVER (ORDER BY "rank" ASC, "term" ASC) AS rn
    FROM target_rows
)
SELECT "term",
       "rank",
       "week"
FROM ordered
WHERE rn = 1;