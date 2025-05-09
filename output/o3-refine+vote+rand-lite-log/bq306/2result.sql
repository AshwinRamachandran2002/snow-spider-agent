-- Top 10 tags for user 1908967 based on answers posted before 7 Jun 2018
WITH user_answers AS (
  SELECT
    id   AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  SELECT
    ua.answer_id,
    ua.question_id,
    SUM(IF(v.vote_type_id = 2, 1, 0)) AS upvotes,          -- vote_type_id = 2  → up‑vote
    SUM(IF(v.vote_type_id = 1, 1, 0)) AS accepted          -- vote_type_id = 1  → accepted‑answer
  FROM user_answers AS ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
    ON v.post_id = ua.answer_id
   AND v.vote_type_id IN (1, 2)                           -- keep only needed vote kinds
  GROUP BY ua.answer_id, ua.question_id
),
answer_tags AS (
  SELECT
    av.answer_id,
    tag,
    av.upvotes,
    av.accepted
  FROM answer_votes AS av
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = av.question_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag            -- explode tags
)
SELECT
  tag,
  SUM(10 * upvotes + 15 * accepted) AS total_score
FROM answer_tags
GROUP BY tag
ORDER BY total_score DESC, tag
LIMIT 10;