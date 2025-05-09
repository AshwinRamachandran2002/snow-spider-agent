SELECT
    "refresh_date",
    "week",
    "rank",
    "term"
FROM
    "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE
    "week" BETWEEN '2024-09-01' AND '2024-09-14'   -- requested two‑week window
    AND "rank" IN (1, 2, 3)                        -- top three ranks
ORDER BY
    "refresh_date" DESC NULLS LAST,                -- newest refresh_date first
    "rank" ASC;                                    -- rank 1, 2, 3 within each refresh_date