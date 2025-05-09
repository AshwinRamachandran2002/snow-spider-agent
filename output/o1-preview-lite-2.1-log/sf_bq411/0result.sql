SELECT
    "week" AS "Date",
    MAX(CASE WHEN "rank" = 1 THEN "term" END) AS "Term1",
    MAX(CASE WHEN "rank" = 2 THEN "term" END) AS "Term2"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE
    "week" BETWEEN '2024-09-01' AND '2024-09-14'
    AND "rank" <= 2
GROUP BY
    "week"
ORDER BY
    "week" DESC NULLS LAST;