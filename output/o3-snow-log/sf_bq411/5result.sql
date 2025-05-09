/* Top-3 Google-Trends terms for each weekday (Mon-Fri)
   whose “week” falls between 2024-09-01 and 2024-09-14,
   grouped by the corresponding “refresh_date”.           */
WITH per_rank AS (
    SELECT
        "refresh_date",
        "rank",
        MIN("term") AS "term"           -- one representative term per date/rank
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_TERMS"
    WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
      AND DAYOFWEEK("refresh_date") BETWEEN 1 AND 5      -- 1 = Monday … 5 = Friday
      AND "rank" IN (1, 2, 3)
    GROUP BY "refresh_date", "rank"
)
SELECT
    "refresh_date",
    MAX(CASE WHEN "rank" = 1 THEN "term" END) AS "rank_1_term",
    MAX(CASE WHEN "rank" = 2 THEN "term" END) AS "rank_2_term",
    MAX(CASE WHEN "rank" = 3 THEN "term" END) AS "rank_3_term"
FROM per_rank
GROUP BY "refresh_date"
ORDER BY "refresh_date" DESC NULLS LAST;