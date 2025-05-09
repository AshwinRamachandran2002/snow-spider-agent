WITH questions_2022 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("creation_date" / 1000000)) AS "month_ts",
        "tags"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "creation_date" >= 1640995200000000          -- 2022-01-01
      AND "creation_date" <  1672531200000000          -- 2023-01-01
),
total_q AS (
    SELECT
        "month_ts",
        COUNT(*) AS total_questions
    FROM questions_2022
    GROUP BY "month_ts"
),
python_q AS (
    SELECT
        "month_ts",
        COUNT(*) AS python_questions
    FROM questions_2022
    WHERE REGEXP_LIKE("tags", '(^|\|)python(\||$)', 'i')   -- “python” as an individual tag
    GROUP BY "month_ts"
)
SELECT
    TO_CHAR(t."month_ts", 'YYYY-MM')                                   AS "year_month",
    COALESCE(p.python_questions, 0)                                    AS "python_questions",
    t.total_questions,
    ROUND(COALESCE(p.python_questions, 0) / t.total_questions, 4)      AS "python_proportion"
FROM total_q t
LEFT JOIN python_q p
  ON t."month_ts" = p."month_ts"
ORDER BY "year_month";