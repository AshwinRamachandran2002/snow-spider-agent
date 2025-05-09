/* Top 10 tags for user 1908967 based on answers before 2018‑06‑07 */
WITH user_answers AS (
  SELECT
    id AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  SELECT
    ua.answer_id,
    COUNTIF(v.vote_type_id = 2) AS upvotes,
    COUNTIF(v.vote_type_id = 1) AS accepted_marks
  FROM user_answers ua
  LEFT JOIN `bigquery-public-data.stackoverflow.votes` v
    ON v.post_id = ua.answer_id
  GROUP BY ua.answer_id
),
answer_tags AS (
  SELECT
    ua.answer_id,
    tag
  FROM user_answers ua
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.id = ua.question_id
  CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
)
SELECT
  tag,
  SUM(10 * av.upvotes + 15 * av.accepted_marks) AS total_score
FROM answer_tags ans
JOIN answer_votes av
  ON av.answer_id = ans.answer_id
GROUP BY tag
ORDER BY total_score DESC
LIMIT 10;