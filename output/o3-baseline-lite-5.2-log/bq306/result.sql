WITH user_answers AS (
  SELECT
    id AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
votes_per_answer AS (
  SELECT
    post_id AS answer_id,
    SUM(IF(vote_type_id = 2, 1, 0)) AS upvotes,
    SUM(IF(vote_type_id = 1, 1, 0)) AS accepted
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1, 2)
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY answer_id
),
answer_scores AS (
  SELECT
    ua.answer_id,
    10 * COALESCE(v.upvotes, 0) +
    15 * COALESCE(v.accepted, 0)           AS score,
    q.tags
  FROM user_answers AS ua
  LEFT JOIN votes_per_answer AS v
       ON ua.answer_id = v.answer_id
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON ua.question_id = q.id
  WHERE q.tags IS NOT NULL
),
tag_scores AS (
  SELECT
    tag,
    SUM(score) AS total_score
  FROM answer_scores,
       UNNEST(SPLIT(tags, '|')) AS tag
  GROUP BY tag
)
SELECT
  tag AS tag_name,
  total_score
FROM tag_scores
ORDER BY total_score DESC
LIMIT 10;