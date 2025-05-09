WITH answers AS (
  -- Answers written by the user before 7 Jun 2018
  SELECT
    id AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
votes AS (
  -- Count up‑votes and accepted‑answer votes for those answers
  SELECT
    post_id,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted_votes
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE post_id IN (SELECT answer_id FROM answers)
  GROUP BY post_id
),
answer_scores AS (
  -- Calculate score for each answer
  SELECT
    a.answer_id,
    a.question_id,
    10 * COALESCE(v.upvotes, 0) + 15 * COALESCE(v.accepted_votes, 0) AS answer_score
  FROM answers AS a
  LEFT JOIN votes AS v
    ON a.answer_id = v.post_id
),
tags_per_answer AS (
  -- Attach each answer’s score to every tag on its question
  SELECT
    tag,
    s.answer_score
  FROM answer_scores AS s
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = s.question_id
  CROSS JOIN UNNEST(SPLIT(COALESCE(q.tags, ''), '|')) AS tag
  WHERE tag <> ''         -- exclude empty strings when a question has no tags
)
SELECT
  tag,
  SUM(answer_score) AS total_score
FROM tags_per_answer
GROUP BY tag
ORDER BY total_score DESC, tag
LIMIT 10;