/*  Top-3 Google-Trends terms (ranks 1–3) for weekdays
    Monday-through-Friday between 1-Sep-2024 and 14-Sep-2024,
    grouped by refresh_date and listed newest first              */
WITH ranked AS (
    SELECT
        "refresh_date",
        "rank",
        "term",
        ROW_NUMBER() OVER (
            PARTITION BY "refresh_date", "rank"
            ORDER BY "term"           -- deterministic tie-breaker
        ) AS rn
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
    WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'  -- target period
      AND "rank" IN (1, 2, 3)                           -- top-3 ranks
      AND DAYOFWEEK("refresh_date") BETWEEN 1 AND 5     -- Mon (1) … Fri (5)
)
SELECT
    "refresh_date",
    MAX(CASE WHEN "rank" = 1 THEN "term" END) AS "rank_1_term",
    MAX(CASE WHEN "rank" = 2 THEN "term" END) AS "rank_2_term",
    MAX(CASE WHEN "rank" = 3 THEN "term" END) AS "rank_3_term"
FROM ranked
WHERE rn = 1                      -- keep one term per rank/refresh_date
GROUP BY "refresh_date"
ORDER BY "refresh_date" DESC NULLS LAST;