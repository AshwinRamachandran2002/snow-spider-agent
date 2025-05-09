/* Identify the top-ranked rising search term(s) for the week that is
   exactly one year (-52 weeks) before the latest available week, using
   the most-recent refresh batch. */
WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
),
latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS" tr
    JOIN latest_refresh lr
      ON tr."refresh_date" = lr."latest_refresh_date"
),
target_week AS (
    SELECT DATEADD(week, -52, "latest_week") AS "target_week"
    FROM latest_week
),
top_rank AS (
    SELECT MIN("rank") AS "best_rank"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS" tr
    JOIN latest_refresh lr
      ON tr."refresh_date" = lr."latest_refresh_date"
    JOIN target_week tw
      ON tr."week" = tw."target_week"
)
SELECT
    tr."term"          AS "top_rising_term",
    tr."rank",
    tr."week",
    tr."percent_gain",
    tr."dma_name",
    tr."dma_id"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS" tr
JOIN latest_refresh lr
  ON tr."refresh_date" = lr."latest_refresh_date"
JOIN target_week tw
  ON tr."week" = tw."target_week"
JOIN top_rank trk
  ON tr."rank" = trk."best_rank"
ORDER BY
    tr."rank",
    tr."dma_name" NULLS LAST;