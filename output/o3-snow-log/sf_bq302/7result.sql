SELECT
  DATE_TRUNC('month', TO_TIMESTAMP_NTZ("creation_date" / 1000000))      AS "month_2022",
  ROUND(
        SUM(CASE
                WHEN REGEXP_LIKE("tags", '(^|\\|)python(\\||$)') THEN 1
                ELSE 0
            END)::FLOAT
        / COUNT(*), 
        4
  )                                                                     AS "python_proportion"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE YEAR(TO_TIMESTAMP_NTZ("creation_date" / 1000000)) = 2022
GROUP BY 1
ORDER BY 1;