SELECT
    TO_CHAR(
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ("creation_date" / 1000000)),
        'YYYY-MM'
    )                                                     AS "month",
    COUNT(*)                                              AS "total_questions",
    SUM(
        CASE
            WHEN REGEXP_LIKE("tags", '(^|\|)python(\||$)', 'i') THEN 1
            ELSE 0
        END
    )                                                     AS "python_questions",
    ROUND(
        SUM(
            CASE
                WHEN REGEXP_LIKE("tags", '(^|\|)python(\||$)', 'i') THEN 1
                ELSE 0
            END
        )::FLOAT
        / COUNT(*),
        4
    )                                                     AS "python_share"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
WHERE DATE_TRUNC(
          'year',
          TO_TIMESTAMP_LTZ("creation_date" / 1000000)
      ) = '2022-01-01'
GROUP BY 1
ORDER BY 1;