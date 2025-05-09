WITH q2022 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("creation_date" / 1000000)) AS "month",
        "tags"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    -- 2022-01-01 00:00:00  to  2022-12-31 23:59:59 (micro-second epoch)
    WHERE "creation_date" BETWEEN 1640995200000000 AND 1672531199999999
)
SELECT
    "month",
    COUNT_IF(LOWER("tags") LIKE '%python%')                            AS "python_questions",
    COUNT(*)                                                           AS "all_questions",
    ROUND(
        COUNT_IF(LOWER("tags") LIKE '%python%')::FLOAT / COUNT(*), 4
    )                                                                  AS "python_proportion"
FROM q2022
GROUP BY "month"
ORDER BY "month";