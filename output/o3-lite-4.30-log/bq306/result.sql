WITH answer_scores AS (
  SELECT
    a.id        AS answer_id,
    a.parent_id AS question_id,
    10 * COUNTIF(v.vote_type_id = 2) +
    15 * COUNTIF(v.vote_type_id = 1) AS answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN `bigquery-public-data.stackoverflow.votes`          AS v
    ON v.post_id = a.id
  WHERE a.owner_user_id = 1908967
    AND a.creation_date < '2018-06-07'
    AND v.vote_type_id IN (1, 2)
  GROUP BY answer_id, question_id
),
question_tags AS (
  SELECT
    q.id AS question_id,
    tag
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q,
       UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE q.tags IS NOT NULL
)
SELECT
  qt.tag,
  SUM(ans.answer_score) AS total_score
FROM answer_scores AS ans
JOIN question_tags AS qt
  ON qt.question_id = ans.question_id
GROUP BY qt.tag
ORDER BY total_score DESC, qt.tag
LIMIT 10;