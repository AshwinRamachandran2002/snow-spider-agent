/* Top-ranked rising term for the week exactly 52 weeks before the
   latest week, evaluated under the most-recent refresh snapshot */

WITH latest_refresh AS (     -- most-recent snapshot date
    SELECT MAX("refresh_date") AS "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
),  
latest_week AS (             -- latest week within that snapshot
    SELECT MAX("week") AS "week"
    FROM   GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
    WHERE  "refresh_date" = (SELECT "refresh_date" FROM latest_refresh)
),  
target_week AS (             -- week exactly one year (52 weeks) earlier
    SELECT DATEADD('week', -52, "week") AS "week"
    FROM   latest_week
)
SELECT DISTINCT
       "term"
FROM   GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_RISING_TERMS"
WHERE  "refresh_date" = (SELECT "refresh_date" FROM latest_refresh)
  AND  "week"         = (SELECT "week"        FROM target_week)
  AND  "rank" = 1
ORDER BY "term";