WITH answers AS (
  SELECT
    parent_id AS question_id,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),

high_ratio AS (
  -- does the question have any answer whose score / view_count > 0.01 ?
  SELECT
    q.id AS question_id,
    MAX(
      CASE
        WHEN q.view_count IS NOT NULL AND q.view_count <> 0
             THEN (a.score / q.view_count) > 0.01
        ELSE FALSE
      END
    ) AS has_high_ratio
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN answers AS a
    ON a.question_id = q.id
  GROUP BY q.id
),

qualified_questions AS (
  -- keep questions that (a) have an accepted answer OR
  -- (b) no accepted answer but DO have a high-ratio answer
  SELECT q.*
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN high_ratio hr
    ON hr.question_id = q.id
  WHERE q.body IS NOT NULL
    AND (
          q.accepted_answer_id IS NOT NULL
          OR (q.accepted_answer_id IS NULL AND hr.has_high_ratio)
        )
),

top10 AS (
  -- 10 longest question bodies that satisfy the rule
  SELECT
    id,
    owner_user_id,
    LENGTH(body) AS body_length
  FROM qualified_questions
  ORDER BY body_length DESC
  LIMIT 10
),

user_stats AS (
  SELECT
    id AS user_id,
    reputation,
    (up_votes - down_votes) AS net_votes
  FROM `bigquery-public-data.stackoverflow.users`
),

badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS total_badges
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  t.id                       AS question_id,
  t.body_length,
  u.reputation,
  u.net_votes,
  COALESCE(b.total_badges, 0) AS total_badges
FROM top10 AS t
JOIN user_stats     AS u ON u.user_id = t.owner_user_id
LEFT JOIN badge_counts  AS b ON b.user_id = t.owner_user_id
ORDER BY t.body_length DESC;