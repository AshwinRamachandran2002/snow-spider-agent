WITH months(month_num_int) AS (
    SELECT column1 AS month_num_int FROM VALUES
        (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)
)
SELECT
    LPAD(TO_VARCHAR(m.month_num_int), 2, '0') AS "Month_num",
    INITCAP(TO_CHAR(DATE_FROM_PARTS(2022, m.month_num_int, 1), 'MONTH')) AS "Month",
    ROUND(
        COALESCE(monthly_data.python_questions / monthly_data.total_questions, 0),
        4
    ) AS "Proportion"
FROM
    months m
LEFT JOIN
    (
        SELECT
            EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("creation_date" / 1000000)) AS month_num_int,
            COUNT(*) AS total_questions,
            SUM(
                CASE
                    WHEN CONCAT('|', LOWER("tags"), '|') LIKE '%|python|%' THEN 1
                    ELSE 0
                END
            ) AS python_questions
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
        WHERE
            "creation_date" >= 1640995200000000 -- '2022-01-01' in microseconds
            AND "creation_date" < 1672531200000000 -- '2023-01-01' in microseconds
            AND "tags" IS NOT NULL
        GROUP BY
            EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("creation_date" / 1000000))
    ) AS monthly_data
ON m.month_num_int = monthly_data.month_num_int
ORDER BY
    m.month_num_int;