WITH  questions_2021 AS (   -- all questions posted in calendar year 2021
        SELECT  q."id"                                                AS question_id ,
                TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)        AS question_ts ,
                DAYOFWEEK(TO_TIMESTAMP_LTZ(q."creation_date" / 1000000))  AS weekday_num   -- 1-Sunday … 7-Saturday
        FROM   STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
        WHERE  TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)
                 BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59.999'
     ),

     first_answers AS (        -- first answer (if any) for every question in 2021
        SELECT  a."parent_id"                                       AS question_id ,
                MIN(TO_TIMESTAMP_LTZ(a."creation_date" / 1000000))  AS first_answer_ts
        FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        WHERE   TO_TIMESTAMP_LTZ(a."creation_date" / 1000000)
                 BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59.999'
        GROUP BY a."parent_id"
     )

SELECT  q.weekday_num                                                       AS "WEEKDAY_NUM" ,
        TO_CHAR(DATEADD('day', q.weekday_num - 1, '2021-01-03'), 'DAY')     AS "WEEKDAY_NAME", -- 2021-01-03 is a Sunday
        COUNT(*)                                                            AS "QUESTIONS_2021" ,
        COUNT(CASE WHEN DATEDIFF('second', q.question_ts, f.first_answer_ts) <= 3600
                   THEN 1 END)                                              AS "ANSWERED_WITHIN_1H" ,
        ROUND(
              100.0 * COUNT(CASE WHEN DATEDIFF('second', q.question_ts, f.first_answer_ts) <= 3600
                                 THEN 1 END)
              / COUNT(*)
             , 4)                                                           AS "PCT_WITHIN_1H"
FROM    questions_2021 q
LEFT JOIN first_answers f
       ON q.question_id = f.question_id
GROUP BY q.weekday_num
ORDER BY q.weekday_num;