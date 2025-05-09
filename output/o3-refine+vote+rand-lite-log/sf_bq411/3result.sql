SELECT
    "refresh_date",
    "week",
    "term",
    "rank",
    "score"
FROM
    "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE
    "week" BETWEEN DATE '2024-09-01' AND DATE '2024-09-14'  -- weeks starting within 1‑14 Sep 2024
    AND "rank" IN (1, 2, 3)                                 -- only ranks 1, 2, 3
ORDER BY
    "refresh_date" DESC NULLS LAST,                         -- newest refresh_date first
    "week"        DESC NULLS LAST,                          -- newest week within each refresh_date
    "rank"        ASC;                                      -- rank 1 before 2 before 3