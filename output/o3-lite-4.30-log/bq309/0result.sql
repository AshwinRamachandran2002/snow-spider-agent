WITH qualifying_questions AS (
  -- a) questions that have an accepted answer
  SELECT
    q.id,
    q.body,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.accepted_answer_id IS NOT NULL

  UNION DISTINCT

  -- b) questions without an accepted answer
  --    but with at least one answer whose score / view_count > 0.01
  SELECT
    q.id,
    q.body,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
  WHERE q.accepted_answer_id IS NULL
    AND q.view_count > 0
    AND a.score / q.view_count > 0.01
),
longest_10 AS (
  SELECT
    id            AS question_id,
    owner_user_id,
    LENGTH(body)  AS body_length
  FROM qualifying_questions
  ORDER BY body_length DESC, question_id
  LIMIT 10
),
badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS badge_total
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)
SELECT
  l.question_id,
  u.reputation                    AS asker_reputation,
  u.up_votes - u.down_votes       AS asker_net_votes,
  IFNULL(b.badge_total, 0)        AS asker_badge_total
FROM longest_10 AS l
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON u.id = l.owner_user_id
LEFT JOIN badge_counts AS b
  ON b.user_id = u.id
ORDER BY l.body_length DESC, l.question_id;