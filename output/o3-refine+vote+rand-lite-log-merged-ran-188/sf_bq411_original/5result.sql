WITH ranked_terms AS (
    SELECT
        "refresh_date",
        "week",
        "term",
        "rank",
        ROW_NUMBER() OVER (
            PARTITION BY "refresh_date"
            ORDER BY "rank" ASC
        ) AS rn
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
    WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'          -- weeks starting within range
      AND "rank" IS NOT NULL                                    -- ignore rows without rank
)
SELECT
    "refresh_date",
    "week",
    "term",
    "rank"
FROM ranked_terms
WHERE rn <= 3                                                    -- keep ranks 1–3 per refresh_date
ORDER BY
    "refresh_date" DESC NULLS LAST,                              -- most‑recent refresh_date first
    "rank" ASC;                                                  -- rank order 1, 2, 3