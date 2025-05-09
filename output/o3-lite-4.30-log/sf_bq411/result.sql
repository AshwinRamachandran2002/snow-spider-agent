WITH ranked_terms AS (
    SELECT
        "refresh_date",
        "rank",
        "term",
        COUNT(*) AS term_occurrences
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
    WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
      AND DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5   -- Monday‑Friday
      AND "rank" IN (1, 2, 3)
    GROUP BY "refresh_date", "rank", "term"
), picked_terms AS (
    SELECT
        "refresh_date",
        "rank",
        "term",
        ROW_NUMBER() OVER (
            PARTITION BY "refresh_date", "rank"
            ORDER BY term_occurrences DESC, "term"
        ) AS rn
    FROM ranked_terms
)
SELECT
    "refresh_date",
    "rank",
    "term" AS "top_term"
FROM picked_terms
WHERE rn = 1
ORDER BY "refresh_date" DESC NULLS LAST,
         "rank" ASC;