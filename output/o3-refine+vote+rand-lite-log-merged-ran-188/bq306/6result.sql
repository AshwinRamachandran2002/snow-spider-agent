-- Top 10 tags for user 1908967 (answers created before 2018‑06‑07)
WITH user_answers AS (
  SELECT
    id            AS answer_id,
    parent_id     AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (
  SELECT
    post_id,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accept_cnt
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1,2)
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY post_id
),
answer_scores AS (
  SELECT
    ua.answer_id,
    ua.question_id,
    COALESCE(av.upvote_cnt ,0) AS upvotes,
    COALESCE(av.accept_cnt ,0) AS accepts
  FROM user_answers ua
  LEFT JOIN answer_votes av ON av.post_id = ua.answer_id
),
tag_points AS (
  SELECT
    tag,
    SUM(upvotes)*10 + SUM(accepts)*15 AS total_score
  FROM (
    SELECT
      ascr.upvotes,
      ascr.accepts,
      tag
    FROM answer_scores      ascr
    JOIN `bigquery-public-data.stackoverflow.posts_questions` q
         ON q.id = ascr.question_id
    CROSS JOIN UNNEST(SPLIT(q.tags, '|')) AS tag
  )
  GROUP BY tag
)
SELECT
  tag,
  total_score
FROM tag_points
ORDER BY total_score DESC, tag
LIMIT 10;