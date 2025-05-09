WITH
-- all users that signed up in 2021
new_users AS (
  SELECT
    id AS user_id,
    creation_date,
    FORMAT_TIMESTAMP('%Y-%m', creation_date) AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- users who asked at least one question within 30 days of sign‑up
questions_within_30 AS (
  SELECT
    nu.user_id,
    nu.month,
    MIN(q.creation_date) AS first_question_date        -- first question, if any
  FROM new_users AS nu
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = nu.user_id
   AND q.creation_date BETWEEN nu.creation_date
                           AND TIMESTAMP_ADD(nu.creation_date, INTERVAL 30 DAY)
  GROUP BY nu.user_id, nu.month
),

-- of those question‑askers, who answered at least once within 30 days
answers_within_30 AS (
  SELECT DISTINCT
    qw.user_id
  FROM questions_within_30 AS qw
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.owner_user_id = qw.user_id
   AND a.creation_date >  qw.first_question_date
   AND a.creation_date <= TIMESTAMP_ADD(qw.first_question_date, INTERVAL 30 DAY)
)

SELECT
  nu.month,
  COUNT(*)                                         AS total_new_users,
  ROUND(100 * COUNTIF(qw.user_id IS NOT NULL)
/ COUNT(*), 4)                                    AS pct_asked_question_within_30d,
  ROUND(
    100 * COUNTIF(ans.user_id IS NOT NULL)
/ NULLIF(COUNTIF(qw.user_id IS NOT NULL),0), 4)   AS pct_of_askers_who_answered_within_next_30d
FROM new_users            AS nu
LEFT JOIN questions_within_30 AS qw   ON nu.user_id = qw.user_id
LEFT JOIN answers_within_30   AS ans  ON nu.user_id = ans.user_id
GROUP BY nu.month
ORDER BY nu.month;