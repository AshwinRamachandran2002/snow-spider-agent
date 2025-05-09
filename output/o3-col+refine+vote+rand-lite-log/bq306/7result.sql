WITH user_answers AS (
  -- answers by the user before 7 Jun 2018
  SELECT
    id   AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_scores AS (
  -- 10 × up-votes  +  15 × accepted-answer votes
  SELECT
    ua.answer_id,
    10 * SUM(CASE WHEN v.vote_type_id = 2 THEN 1 ELSE 0 END) +
    15 * SUM(CASE WHEN v.vote_type_id = 1 THEN 1 ELSE 0 END) AS answer_score
  FROM user_answers AS ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` AS v
         ON v.post_id = ua.answer_id
  GROUP BY ua.answer_id
),
tag_scores AS (
  -- propagate each answer’s score to all its question’s tags
  SELECT
    tag,
    SUM(ans.answer_score) AS total_score
  FROM answer_scores AS ans
  JOIN user_answers AS ua
        ON ua.answer_id = ans.answer_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = ua.question_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  GROUP BY tag
)
SELECT
  tag,
  total_score
FROM tag_scores
ORDER BY total_score DESC
LIMIT 10;