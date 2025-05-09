WITH  questions AS (
        SELECT  "id"                                                       AS question_id ,
                TO_TIMESTAMP_LTZ("creation_date" / 1000000)               AS question_ts ,
                TO_CHAR(TO_TIMESTAMP_LTZ("creation_date" / 1000000) , 'DY') AS day_name
        FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
), first_answers AS (
        SELECT  "parent_id"                        AS question_id ,
                MIN("creation_date")               AS first_answer_raw
        FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
        GROUP BY "parent_id"
), per_question AS (
        SELECT  q.day_name ,
                CASE 
                     WHEN fa.first_answer_raw IS NOT NULL
                          AND DATEDIFF(
                                  'second',
                                  q.question_ts ,
                                  TO_TIMESTAMP_LTZ(fa.first_answer_raw / 1000000)
                               ) <= 3600
                     THEN 1 ELSE 0 
                END                                                       AS answered_within_hour
        FROM    questions q
        LEFT JOIN first_answers fa
               ON q.question_id = fa.question_id
), stats AS (
        SELECT  day_name ,
                COUNT(*)                                        AS total_q ,
                SUM(answered_within_hour)                       AS answered_fast ,
                ROUND(100.0 * SUM(answered_within_hour) 
                            / COUNT(*) , 4)                     AS pct_within_hour
        FROM    per_question
        GROUP  BY day_name
)
SELECT  day_name ,
        pct_within_hour
FROM   (
        SELECT  day_name ,
                pct_within_hour ,
                ROW_NUMBER() OVER (ORDER BY pct_within_hour DESC NULLS LAST) AS rn
        FROM    stats
) ranked
WHERE  rn = 3;