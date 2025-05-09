SELECT "refresh_date", "term", "rank"
FROM (
    SELECT "refresh_date", "term", "rank",
        ROW_NUMBER() OVER (PARTITION BY "refresh_date", "rank" ORDER BY "score" DESC NULLS LAST) AS rn
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
    WHERE "refresh_date" BETWEEN '2024-09-16' AND '2024-09-27'
      AND DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5
      AND "rank" IN (1, 2, 3)
) sub
WHERE rn = 1
ORDER BY "refresh_date" DESC NULLS LAST, "rank" ASC;