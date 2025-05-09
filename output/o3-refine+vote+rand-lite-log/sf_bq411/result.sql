SELECT
    "refresh_date",
    "term",
    "rank",
    "week",
    "dma_id",
    "dma_name",
    "score"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_TERMS"
WHERE
    "rank" IN (1, 2, 3)                                      -- keep only ranks 1‑3
    AND "week" BETWEEN '2024-09-01' AND '2024-09-14'         -- date window
    AND DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5         -- Monday (1) to Friday (5)
ORDER BY
    "refresh_date" DESC NULLS LAST,                          -- newest refresh first
    "rank"        ASC,
    "term"        ASC;