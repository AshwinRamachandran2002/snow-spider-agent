WITH user_answers AS (
  SELECT
    a.id AS answer_id,
    a.parent_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  WHERE a.owner_user_id = 1908967
    AND a.creation_date < '2018-06-07'
),
votes_per_answer AS (
  SELECT
    v.post_id AS answer_id,
    SUM(IF(v.vote_type_id = 2, 1, 0)) AS upvotes,
    SUM(IF(v.vote_type_id = 1, 1, 0)) AS accepts
  FROM `bigquery-public-data.stackoverflow.votes` v
  JOIN user_answers ua ON ua.answer_id = v.post_id
  WHERE v.vote_type_id IN (1, 2)   -- 1: accepted, 2: up-vote
  GROUP BY answer_id
),
answers_with_tags AS (
  SELECT
    ua.answer_id,
    COALESCE(v.upvotes, 0)  AS upvotes,
    COALESCE(v.accepts, 0)  AS accepts,
    q.tags
  FROM user_answers ua
  LEFT JOIN votes_per_answer v ON v.answer_id = ua.answer_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.id = ua.parent_id
  WHERE q.tags IS NOT NULL
)
SELECT
  tag,
  10 * SUM(upvotes) + 15 * SUM(accepts) AS total_score
FROM answers_with_tags,
     UNNEST(SPLIT(tags, '|')) AS tag
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;