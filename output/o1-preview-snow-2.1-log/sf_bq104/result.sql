SELECT t."dma_name", SUM(t."score") AS "total_search_score"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS t
WHERE t."term" IN (
    SELECT DISTINCT "term"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = '2022-10-09'
)
AND t."week" = '2022-10-09'
GROUP BY t."dma_name"
ORDER BY "total_search_score" DESC NULLS LAST
LIMIT 1;