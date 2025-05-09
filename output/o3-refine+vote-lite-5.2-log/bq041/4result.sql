WITH users_2021 AS (        -- all users that joined in 2021
  SELECT
    id                             AS user_id ,
    creation_date                  AS user_creation_ts ,
    FORMAT_TIMESTAMP('%Y-%m',creation_date) AS month_id
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date)=2021
),

/* first question (if any) asked by the user within 30 days of sign‑up */
first_question AS (
  SELECT
    u.user_id ,
    MIN(q.creation_date) AS first_question_ts        -- first question time
  FROM users_2021            AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.owner_user_id = u.user_id
      AND q.creation_date BETWEEN u.user_creation_ts
                              AND TIMESTAMP_ADD(u.user_creation_ts,INTERVAL 30 DAY)
  GROUP BY u.user_id
),

/* whether the above users answered something within 30 days AFTER
   their first question */
answer_after_question AS (
  SELECT DISTINCT
    fq.user_id
  FROM first_question fq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
       ON  a.owner_user_id = fq.user_id
       AND a.creation_date  > fq.first_question_ts
       AND a.creation_date <= TIMESTAMP_ADD(fq.first_question_ts,INTERVAL 30 DAY)
)

/* monthly statistics */
SELECT
  u.month_id                                         AS month ,
  COUNT(*)                                           AS total_new_users ,
  ROUND( COUNTIF(fq.user_id IS NOT NULL) / COUNT(*)
       ,4)                                           AS pct_asked_question_within_30 ,
  ROUND( COUNTIF(aq.user_id IS NOT NULL) /
         NULLIF( COUNTIF(fq.user_id IS NOT NULL) ,0)
       ,4)                                           AS pct_of_askers_who_answered_within_30
FROM users_2021                AS u
LEFT JOIN first_question        AS fq ON fq.user_id = u.user_id
LEFT JOIN answer_after_question AS aq ON aq.user_id = u.user_id
GROUP BY month
ORDER BY month;