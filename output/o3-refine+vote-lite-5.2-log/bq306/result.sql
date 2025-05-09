WITH answers AS (
  -- all answers by the user before 7 Jun 2018
  SELECT
    id        AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  -- count up‑votes and accepted‑answer events for each answer
  SELECT
    a.answer_id,
    SUM(IF(v.vote_type_id = 2, 1, 0)) AS upvotes,
    SUM(IF(v.vote_type_id = 1, 1, 0)) AS accepted_votes
  FROM answers a
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` v
    ON v.post_id = a.answer_id
   AND v.vote_type_id IN (1, 2)
  GROUP BY a.answer_id
),
answer_tags AS (
  -- one row per (answer, tag) pair
  SELECT
    a.answer_id,
    tag
  FROM answers a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.id = a.question_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag <> ''
),
tag_scores AS (
  SELECT
    atg.tag,
    10 * COALESCE(av.upvotes, 0) +
    15 * COALESCE(av.accepted_votes, 0) AS score
  FROM answer_tags atg
  LEFT JOIN answer_votes av
    ON atg.answer_id = av.answer_id
)
SELECT
  tag,
  SUM(score) AS total_score
FROM tag_scores
GROUP BY tag
ORDER BY total_score DESC, tag
LIMIT 10;