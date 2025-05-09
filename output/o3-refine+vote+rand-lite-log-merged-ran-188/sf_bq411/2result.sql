SELECT
    "refresh_date",
    "term",
    "rank"
FROM
    "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE
    "week" BETWEEN '2024-09-01' AND '2024-09-14'
    AND "rank" IN (1, 2, 3)
    AND TO_CHAR("week", 'DY') NOT IN ('SAT', 'SUN')   -- Monday-Friday only
ORDER BY
    "refresh_date" DESC NULLS LAST,
    "rank";