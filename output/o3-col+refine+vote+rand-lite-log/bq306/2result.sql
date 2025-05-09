-- Top-10 tags for answers written by user 1908967 before 7 Jun 2018
WITH user_answers AS (            -- answers by the user
  SELECT
    id        AS answer_id,
    parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id = 1908967
    AND creation_date < '2018-06-07'
),
upvotes AS (                       -- vote_type_id = 2
  SELECT
    post_id,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id = 2
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY post_id
),
accepted AS (                      -- vote_type_id = 1
  SELECT
    post_id,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE vote_type_id = 1
    AND post_id IN (SELECT answer_id FROM user_answers)
  GROUP BY post_id
),
answer_scores AS (                 -- score = 10·upvotes + 15·accepted
  SELECT
    ua.answer_id,
    10 * COALESCE(u.cnt, 0) +
    15 * COALESCE(a.cnt, 0) AS answer_score
  FROM user_answers ua
  LEFT JOIN upvotes  u ON u.post_id = ua.answer_id
  LEFT JOIN accepted a ON a.post_id = ua.answer_id
),
answer_tags AS (                   -- explode tags of corresponding questions
  SELECT
    ua.answer_id,
    tag
  FROM user_answers ua
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.id = ua.question_id
  CROSS JOIN UNNEST(
    REGEXP_EXTRACT_ALL(IFNULL(q.tags, ''), r'[^<>|]+')
  ) AS tag
)
SELECT
  t.tag,
  SUM(s.answer_score) AS total_score
FROM answer_tags   AS t
JOIN answer_scores AS s
  ON s.answer_id = t.answer_id
GROUP BY t.tag
ORDER BY total_score DESC
LIMIT 10;