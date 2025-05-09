/*  Monthly statistics for new Stack Overflow users created in 2021       */
/*  – total new users                                                     */
/*  – % who asked ≥1 question within 30 days of sign-up                   */
/*  – of those askers, % who answered ≥1 question within 30 days after    */
/*    their first question                                                */

WITH new_users AS (          -- all 2021 sign-ups
  SELECT
    id,
    creation_date,
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS yr_mo
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

askers AS (                  -- users who asked within 30 days of sign-up
  SELECT DISTINCT
    u.id,
    u.yr_mo
  FROM new_users AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.id
   AND q.creation_date <= TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
),

first_questions AS (         -- their first question date (any time)
  SELECT
    owner_user_id        AS user_id,
    MIN(creation_date)   AS first_question_date
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  GROUP BY owner_user_id
),

answerers AS (               -- askers who then answered within 30 days of first Q
  SELECT DISTINCT
    fq.user_id,
    nu.yr_mo
  FROM askers AS ak
  JOIN first_questions           AS fq  ON fq.user_id      = ak.id
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
       ON  a.owner_user_id = fq.user_id
       AND a.creation_date >  fq.first_question_date
       AND a.creation_date <= TIMESTAMP_ADD(fq.first_question_date, INTERVAL 30 DAY)
  JOIN new_users AS nu           ON nu.id = fq.user_id     -- to recover yr_mo
)

SELECT
  nu.yr_mo                                            AS month,
  COUNT(DISTINCT nu.id)                               AS new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT ak.id),
                          COUNT(DISTINCT nu.id)), 4)  AS pct_asked_within_30,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT ans.user_id),
                          COUNT(DISTINCT ak.id)), 4)  AS pct_answered_after_asking
FROM new_users      AS nu
LEFT JOIN askers    AS ak   ON ak.id      = nu.id
LEFT JOIN answerers AS ans  ON ans.user_id = nu.id
GROUP BY month
ORDER BY month;