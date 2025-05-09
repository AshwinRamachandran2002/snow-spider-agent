/* Top-ranked rising search term for the week that is one year prior to
   the latest available week (based on the most-recent refresh_date) */

WITH latest_refresh AS (                       -- 1. Most-recent refresh_date
    SELECT MAX("refresh_date") AS refresh_date
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),

latest_week AS (                               -- 2. Latest week in that refresh
    SELECT MAX("week") AS latest_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT refresh_date FROM latest_refresh)
),

target_week AS (                               -- 3. Nearest week ≤ one-year-prior
    SELECT MAX("week") AS target_week
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT refresh_date FROM latest_refresh)
      AND "week" <= DATEADD(year, -1, (SELECT latest_week FROM latest_week))
),

best_rank AS (                                 -- 4. Best (lowest) rank in that week
    SELECT MIN("rank") AS best_rank
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT refresh_date FROM latest_refresh)
      AND "week"        = (SELECT target_week   FROM target_week)
),

term_counts AS (                               -- 5. How many DMAs share that term
    SELECT "term",
           COUNT(*) AS row_cnt
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT refresh_date FROM latest_refresh)
      AND "week"        = (SELECT target_week   FROM target_week)
      AND "rank"        = (SELECT best_rank     FROM best_rank)
    GROUP BY "term"
)

SELECT "term"
FROM term_counts
ORDER BY row_cnt DESC NULLS LAST, "term"
LIMIT 1;