WITH filtered AS (
    SELECT DISTINCT
           "refresh_date",
           "term",
           "rank"
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
    WHERE "rank" IN (1, 2, 3)
      AND "week" BETWEEN '2024-09-01' AND '2024-09-14'   -- limit to the specified two-week span
      AND DAYOFWEEK("refresh_date") BETWEEN 2 AND 6       -- keep only Monday-Friday refreshes
)
SELECT
       "refresh_date",
       "term",
       "rank"
FROM   filtered
ORDER  BY
       "refresh_date" DESC NULLS LAST,
       "rank";