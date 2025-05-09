WITH Questions AS (
    SELECT
        q."id" AS "question_id",
        q."creation_date" AS "question_creation_date",
        DAYNAME(TO_TIMESTAMP(q."creation_date" / 1e6)) AS "Day_of_Week"
    FROM
        STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    WHERE
        q."creation_date" >= 1609459200000000 AND q."creation_date" < 1640995200000000
), QuestionAnswers AS (
    SELECT
        q."question_id",
        q."Day_of_Week",
        CASE WHEN COUNT(a."id") > 0 THEN 1 ELSE 0 END AS "Answered_Within_One_Hour"
    FROM
        Questions q
        LEFT JOIN
            STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
        ON
            a."parent_id" = q."question_id"
            AND a."creation_date" >= q."question_creation_date"
            AND a."creation_date" <= q."question_creation_date" + 3600000000
    GROUP BY
        q."question_id", q."Day_of_Week"
)
SELECT
    "Day_of_Week",
    COUNT(*) AS "Questions_Asked",
    SUM("Answered_Within_One_Hour") AS "Answered_Within_One_Hour",
    ROUND(SUM("Answered_Within_One_Hour") * 100.0 / COUNT(*), 4) AS "Percentage_Answered"
FROM
    QuestionAnswers
GROUP BY
    "Day_of_Week"
ORDER BY
    CASE
        WHEN "Day_of_Week" = 'Monday' THEN 1
        WHEN "Day_of_Week" = 'Tuesday' THEN 2
        WHEN "Day_of_Week" = 'Wednesday' THEN 3
        WHEN "Day_of_Week" = 'Thursday' THEN 4
        WHEN "Day_of_Week" = 'Friday' THEN 5
        WHEN "Day_of_Week" = 'Saturday' THEN 6
        WHEN "Day_of_Week" = 'Sunday' THEN 7
    END;