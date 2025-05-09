SELECT
    "refresh_date",
    "week",
    "rank",
    "term",
    "dma_id",
    "dma_name",
    "score"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE
    "rank" IN (1, 2, 3)                                   -- top‑3 ranks
    AND "week" BETWEEN '2024-09-01' AND '2024-09-14'      -- requested 2‑week range
    AND DAYOFWEEK("refresh_date") BETWEEN 2 AND 6         -- Monday (2) … Friday (6)
ORDER BY
    "refresh_date" DESC NULLS LAST,                       -- latest refresh first
    "rank",
    "term";