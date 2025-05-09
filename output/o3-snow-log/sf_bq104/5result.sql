/* 1) get most-recent refresh_date
   2) find the latest week within that refresh
   3) shift that week back exactly 52 weeks
   4) return the term(s) with the best (lowest) rank for that prior week   */
WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
), latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "refresh_date" FROM latest_refresh)
), target_week AS (
    SELECT DATEADD('week', -52, "latest_week") AS "target_week"
    FROM   latest_week
)
SELECT  "term",
        "rank",
        "dma_name",
        "dma_id",
        "week",
        "refresh_date"
FROM    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
WHERE   "refresh_date" = (SELECT "refresh_date" FROM latest_refresh)
  AND   "week"        = (SELECT "target_week"  FROM target_week)
ORDER BY "rank" ASC NULLS LAST
LIMIT 1;