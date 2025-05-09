WITH latest_week AS (
    -- Most recent week in the entire table
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
anchor_date AS (
    -- Date exactly one year before that latest week
    SELECT DATEADD(year, -1, "latest_week") AS "anchor"
    FROM latest_week
),
chosen_week AS (
    -- The closest week ≤ anchor date (ensures the week exists in the data)
    SELECT MAX("week") AS "chosen_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS, anchor_date
    WHERE "week" <= "anchor"
),
best_rank AS (
    -- Best (minimum) rank in that chosen week
    SELECT MIN("rank") AS "top_rank"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT "chosen_week" FROM chosen_week)
)
-- Return the top-ranked rising search term(s) for the chosen week
SELECT
    "term",
    "rank",
    "percent_gain",
    "week"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE "week" = (SELECT "chosen_week" FROM chosen_week)
  AND "rank" = (SELECT "top_rank" FROM best_rank)
ORDER BY "term";