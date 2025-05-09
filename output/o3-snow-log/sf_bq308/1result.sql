WITH "QUESTIONS_2021" AS (
    SELECT
        q."id"                                                   AS "QUESTION_ID",
        TO_TIMESTAMP_NTZ(q."creation_date" / 1000000)            AS "QUESTION_TS",
        DAYOFWEEK(TO_TIMESTAMP_NTZ(q."creation_date" / 1000000)) AS "DOW_NUM",   -- 1 = Sunday … 7 = Saturday
        TO_CHAR(TO_TIMESTAMP_NTZ(q."creation_date" / 1000000), 'Day')            AS "DOW_NAME"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    WHERE TO_TIMESTAMP_NTZ(q."creation_date" / 1000000) >= '2021-01-01'
      AND TO_TIMESTAMP_NTZ(q."creation_date" / 1000000) <  '2022-01-01'
),
"FIRST_ANSWERS" AS (
    SELECT
        a."parent_id"                                           AS "QUESTION_ID",
        MIN(TO_TIMESTAMP_NTZ(a."creation_date" / 1000000))      AS "FIRST_ANSWER_TS"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    GROUP BY a."parent_id"
),
"Q_WITH_FLAG" AS (
    SELECT
        q."DOW_NUM",
        RTRIM(q."DOW_NAME")                                     AS "DOW_NAME",
        CASE
            WHEN fa."FIRST_ANSWER_TS" IS NOT NULL
             AND DATEDIFF('second', q."QUESTION_TS", fa."FIRST_ANSWER_TS") <= 3600
            THEN 1 ELSE 0
        END                                                     AS "ANS_WITHIN_1H"
    FROM "QUESTIONS_2021" q
    LEFT JOIN "FIRST_ANSWERS" fa
           ON q."QUESTION_ID" = fa."QUESTION_ID"
)
SELECT
    "DOW_NAME"                                             AS "DAY_OF_WEEK",
    COUNT(*)                                               AS "TOTAL_QUESTIONS",
    SUM("ANS_WITHIN_1H")                                   AS "ANSWERED_WITHIN_1_HOUR",
    ROUND(SUM("ANS_WITHIN_1H") * 100.0 / COUNT(*), 4)      AS "PCT_ANSWERED_WITHIN_1_HOUR"
FROM "Q_WITH_FLAG"
GROUP BY "DOW_NUM", "DOW_NAME"
ORDER BY "DOW_NUM";