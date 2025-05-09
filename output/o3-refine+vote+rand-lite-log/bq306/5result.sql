WITH my_answers AS (
  -- answers written by the user before 7 June 2018
  SELECT
    id AS answer_id,
    parent_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_scores AS (
  -- score of every answer: 10 × up‑votes  + 15 × accepted‑answer votes
  SELECT
    v.post_id            AS answer_id,
    SUM(
      CASE v.vote_type_id
           WHEN 2 THEN 10      -- up‑vote
           WHEN 1 THEN 15      -- accepted
      END
    ) AS score
  FROM `bigquery-public-data.stackoverflow.votes` v
  JOIN my_answers a
    ON a.answer_id = v.post_id
  WHERE v.vote_type_id IN (1, 2)    -- only up‑votes and accepted
  GROUP BY v.post_id
),
tags_per_answer AS (
  -- explode tags of the question each answer belongs to
  SELECT
    a.answer_id,
    tag
  FROM my_answers a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag IS NOT NULL AND tag <> ''
)

SELECT
  tag,
  SUM(IFNULL(s.score, 0)) AS total_score
FROM tags_per_answer t
LEFT JOIN answer_scores s
  ON t.answer_id = s.answer_id
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;