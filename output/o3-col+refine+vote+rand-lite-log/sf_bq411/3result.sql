WITH ranked_terms AS (   -- pre-filter the data once
    SELECT DISTINCT
           "refresh_date",
           "rank",
           "term"
    FROM   GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
    WHERE  "week" BETWEEN '2024-09-01' AND '2024-09-14'   -- target window
       AND "rank" IN (1, 2, 3)                            -- only top-3 ranks
       AND DAYOFWEEK("refresh_date") BETWEEN 1 AND 5      -- Monday–Friday
)
SELECT
    "refresh_date",
    LISTAGG(CASE WHEN "rank" = 1 THEN "term" END, ', ')
        WITHIN GROUP (ORDER BY "term")  AS "rank_1_terms",
    LISTAGG(CASE WHEN "rank" = 2 THEN "term" END, ', ')
        WITHIN GROUP (ORDER BY "term")  AS "rank_2_terms",
    LISTAGG(CASE WHEN "rank" = 3 THEN "term" END, ', ')
        WITHIN GROUP (ORDER BY "term")  AS "rank_3_terms"
FROM   ranked_terms
GROUP  BY "refresh_date"
ORDER  BY "refresh_date" DESC NULLS LAST;