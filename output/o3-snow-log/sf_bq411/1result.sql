SELECT
    "refresh_date",
    "week",
    "rank",
    "term",
    "dma_name",
    "dma_id"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
  AND "rank" IN (1, 2, 3)
  -- Keep only Monday (2) through Friday (6)
  AND DAYOFWEEK("refresh_date") BETWEEN 2 AND 6
ORDER BY
    "refresh_date" DESC NULLS LAST,
    "rank" ASC,
    "term";