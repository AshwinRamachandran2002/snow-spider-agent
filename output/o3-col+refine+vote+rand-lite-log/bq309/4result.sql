WITH questions AS (
  SELECT
    id,
    owner_user_id,
    accepted_answer_id,
    view_count,
    LENGTH(body) AS body_len
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- questions without an accepted answer but having at least one answer
-- whose (answer-score / question-view) ratio > 0.01
ratio_qualified AS (
  SELECT
    a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN questions AS q
    ON q.id = a.parent_id
  WHERE q.accepted_answer_id IS NULL
    AND q.view_count > 0
    AND SAFE_DIVIDE(a.score, CAST(q.view_count AS FLOAT64)) > 0.01
  GROUP BY a.parent_id
),

-- union of questions that either have an accepted answer
-- or satisfy the ratio condition above
qualified_questions AS (
  SELECT * FROM questions
  WHERE accepted_answer_id IS NOT NULL
  
  UNION DISTINCT
  
  SELECT q.*
  FROM questions AS q
  JOIN ratio_qualified AS r
    ON r.question_id = q.id
),

-- user reputation and net votes
user_stats AS (
  SELECT
    id AS user_id,
    reputation,
    (up_votes - down_votes) AS net_votes
  FROM `bigquery-public-data.stackoverflow.users`
),

-- total badge count per user
badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS badge_cnt
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  qq.id            AS question_id,
  qq.body_len,
  us.reputation,
  us.net_votes,
  COALESCE(bc.badge_cnt, 0) AS badge_cnt
FROM qualified_questions AS qq
JOIN user_stats        AS us ON us.user_id = qq.owner_user_id
LEFT JOIN badge_counts AS bc ON bc.user_id = qq.owner_user_id
ORDER BY qq.body_len DESC
LIMIT 10;