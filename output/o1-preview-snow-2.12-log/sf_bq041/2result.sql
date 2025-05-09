WITH new_users AS (
    SELECT u."id" AS user_id,
           DATE_TRUNC('month', TO_TIMESTAMP_NTZ(u."creation_date" / 1e6)) AS "month",
           TO_TIMESTAMP_NTZ(u."creation_date" / 1e6) AS creation_timestamp
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    WHERE TO_TIMESTAMP_NTZ(u."creation_date" / 1e6) >= '2021-01-01' AND TO_TIMESTAMP_NTZ(u."creation_date" / 1e6) < '2022-01-01'
),
user_question_stats AS (
    SELECT pq."owner_user_id" AS user_id,
           MIN(TO_TIMESTAMP_NTZ(pq."creation_date" / 1e6)) AS first_question_timestamp
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
    GROUP BY pq."owner_user_id"
),
user_answer_stats AS (
    SELECT pa."owner_user_id" AS user_id,
           MIN(TO_TIMESTAMP_NTZ(pa."creation_date" / 1e6)) AS first_answer_timestamp
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS pa
    GROUP BY pa."owner_user_id"
),
user_activity AS (
    SELECT n.user_id,
           n."month",
           CASE WHEN q.user_id IS NOT NULL THEN 1 ELSE 0 END AS asked_question,
           CASE WHEN q.first_question_timestamp <= n.creation_timestamp + INTERVAL '30 days' THEN 1 ELSE 0 END AS asked_within_30,
           CASE WHEN a.first_answer_timestamp <= n.creation_timestamp + INTERVAL '30 days' THEN 1 ELSE 0 END AS answered_within_30,
           CASE WHEN q.first_question_timestamp <= n.creation_timestamp + INTERVAL '30 days'
                 AND a.first_answer_timestamp <= n.creation_timestamp + INTERVAL '30 days' THEN 1 ELSE 0 END AS asked_and_answered_within_30
    FROM new_users n
    LEFT JOIN user_question_stats q ON n.user_id = q.user_id
    LEFT JOIN user_answer_stats a ON n.user_id = a.user_id
)
SELECT TO_CHAR(ua."month", 'YYYY-MM') AS "Month",
       COUNT(*) AS New_Users,
       ROUND(COUNT(CASE WHEN ua.asked_question = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS Percentage_Asked_Questions,
       ROUND(COUNT(CASE WHEN ua.asked_and_answered_within_30 = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS Percentage_Asked_And_Answered_Within_30_Days
FROM user_activity ua
GROUP BY ua."month"
ORDER BY ua."month";