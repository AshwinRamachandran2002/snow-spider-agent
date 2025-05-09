/* Top-ranked rising search term for the week exactly one year
   before the latest week, using the freshest data available
   for that target week                                            */

WITH latest_week AS (                              -- 1. latest week overall
    SELECT MAX("week") AS latest_week
    FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
),
target_week AS (                                  -- 2. week exactly 52 weeks earlier
    SELECT DATEADD(week, -52, latest_week) AS target_week
    FROM   latest_week
),
target_refresh AS (                               -- 3. most-recent refresh_date for that week
    SELECT MAX("refresh_date") AS target_refresh_date
    FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN   target_week tw
      ON   tr."week" = tw.target_week
),
target_rows AS (                                  -- 4. rows for target week + freshest refresh
    SELECT tr."term",
           tr."rank"
    FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN   target_week   tw ON tr."week"         = tw.target_week
    JOIN   target_refresh trf ON tr."refresh_date" = trf.target_refresh_date
),
best_rank AS (                                    -- 5. best (lowest) rank in that subset
    SELECT MIN("rank") AS min_rank
    FROM   target_rows
)
-- 6. Return the term(s) with that best rank
SELECT DISTINCT tr."term",
       tr."rank"
FROM   target_rows tr
JOIN   best_rank  br ON tr."rank" = br.min_rank;