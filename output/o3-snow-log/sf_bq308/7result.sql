WITH "QUESTIONS_2021" AS (            -- all questions asked in 2021
    SELECT  "id"                                                  AS "qid",
            TO_TIMESTAMP("creation_date" / 1000000)               AS "q_ts",
            DAYNAME(TO_TIMESTAMP("creation_date" / 1000000))      AS "dow",
            DAYOFWEEKISO(TO_TIMESTAMP("creation_date" / 1000000)) AS "dow_num"
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE   TO_TIMESTAMP("creation_date" / 1000000) >= '2021-01-01'
      AND   TO_TIMESTAMP("creation_date" / 1000000) <  '2022-01-01'
),
"FIRST_ANSWERS" AS (                 -- first answer for every question
    SELECT  "parent_id"                                  AS "qid",
            MIN(TO_TIMESTAMP("creation_date" / 1000000)) AS "first_answer_ts"
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
"QA" AS (                            -- join questions to their first answers
    SELECT  q."dow",
            q."dow_num",
            DATEDIFF('second', q."q_ts", a."first_answer_ts") AS "secs_to_answer"
    FROM    "QUESTIONS_2021" q
    LEFT JOIN "FIRST_ANSWERS" a
           ON a."qid" = q."qid"
)
SELECT  "dow"                                             AS "DAY_OF_WEEK",
        COUNT(*)                                          AS "TOTAL_QUESTIONS",
        COUNT_IF("secs_to_answer" <= 3600)                AS "ANSWERED_WITHIN_ONE_HOUR",
        ROUND(COUNT_IF("secs_to_answer" <= 3600) * 100.0 
              / COUNT(*), 4)                              AS "PCT_ANSWERED_WITHIN_ONE_HOUR"
FROM    "QA"
GROUP BY "dow", "dow_num"
ORDER BY "dow_num" NULLS LAST;