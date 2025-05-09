WITH user_answers AS (
  -- answers written by the user before 7 June 2018
  SELECT
    id            AS answer_id,
    parent_id     AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  -- count up‑votes and accepts on those answers
  SELECT
    post_id,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accepts
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1,2)
  GROUP BY post_id
),
answer_scores AS (
  -- compute score for each answer
  SELECT
    ua.answer_id,
    ua.question_id,
    10*COALESCE(av.upvotes,0) + 15*COALESCE(av.accepts,0) AS score
  FROM user_answers ua
  LEFT JOIN answer_votes av
    ON ua.answer_id = av.post_id
),
tags_expanded AS (
  -- attach question tags to each answer and explode
  SELECT
    a.score,
    tag
  FROM answer_scores a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.question_id = q.id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
)
-- aggregate scores per tag and return top‑10
SELECT
  tag,
  SUM(score) AS total_score
FROM tags_expanded
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;