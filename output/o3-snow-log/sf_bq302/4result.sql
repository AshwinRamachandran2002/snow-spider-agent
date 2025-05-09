WITH month_totals AS (
    SELECT
        DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP_NTZ("creation_date" / 1000000)))
            AS "month_2022",
        COUNT(*) AS "total_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "creation_date" BETWEEN 1640995200000000  -- 2022-01-01
                             AND 1672531199000000  -- 2022-12-31 23:59:59
    GROUP BY 1
),
python_totals AS (
    SELECT
        DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP_NTZ("creation_date" / 1000000)))
            AS "month_2022",
        COUNT(*) AS "python_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "creation_date" BETWEEN 1640995200000000 AND 1672531199000000
      AND "tags" ILIKE '%python%'
    GROUP BY 1
)
SELECT
    t."month_2022",
    ROUND(COALESCE(p."python_cnt", 0) / t."total_cnt", 4) AS "python_question_share"
FROM month_totals t
LEFT JOIN python_totals p
       ON t."month_2022" = p."month_2022"
ORDER BY t."month_2022";