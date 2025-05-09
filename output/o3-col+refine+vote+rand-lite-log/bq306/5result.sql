WITH user_answers AS (
  SELECT
    id        AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
answer_votes AS (   -- up-votes and accepted-answer votes per answer
  SELECT
    post_id AS answer_id,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted_cnt,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvote_cnt
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id IN (1, 2)
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY post_id
),
answer_tags AS (    -- explode tags of parent questions
  SELECT
    ua.answer_id,
    tag
  FROM user_answers AS ua
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = ua.question_id,
  UNNEST(SPLIT(q.tags, '|')) AS tag
)
SELECT
  atg.tag,
  SUM(10 * COALESCE(av.upvote_cnt, 0) +
      15 * COALESCE(av.accepted_cnt, 0)) AS total_score
FROM answer_tags AS atg
LEFT JOIN answer_votes AS av
  ON av.answer_id = atg.answer_id
GROUP BY atg.tag
ORDER BY total_score DESC
LIMIT 10;