SELECT
    TO_CHAR("week", 'YYYY-MM-DD') AS "Date",
    MAX(CASE WHEN rn = 1 THEN "term" END) AS "Term1",
    MAX(CASE WHEN rn = 2 THEN "term" END) AS "Term2"
FROM (
    SELECT
        "week",
        "term",
        ROW_NUMBER() OVER (
            PARTITION BY "week"
            ORDER BY SUM("score") DESC NULLS LAST
        ) AS rn
    FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
    WHERE
        "week" BETWEEN '2024-09-01' AND '2024-09-14'
        AND "term" IS NOT NULL
        AND "score" IS NOT NULL
    GROUP BY "week", "term"
) t
WHERE rn <= 2
GROUP BY "week"
ORDER BY "Date" DESC;