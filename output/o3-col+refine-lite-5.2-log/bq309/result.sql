-- Top‑10 longest qualifying Stack Overflow questions
WITH answer_ratio AS (
  -- questions that have at least one answer whose
  -- (answer_score / question_view_count) > 0.01
  SELECT DISTINCT a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  WHERE q.view_count > 0
    AND a.score / q.view_count > 0.01
),

qualifying_questions AS (
  -- questions that (a) have an accepted answer
  --        OR     (b) lack an accepted answer but meet the good‑ratio criterion
  SELECT
    q.id,
    q.owner_user_id,
    LENGTH(q.body) AS body_len
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN answer_ratio ar
    ON ar.question_id = q.id
  WHERE q.accepted_answer_id IS NOT NULL
     OR (q.accepted_answer_id IS NULL AND ar.question_id IS NOT NULL)
),

badge_totals AS (
  SELECT
    user_id,
    COUNT(*) AS badge_cnt
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  qq.id                       AS question_id,
  qq.body_len,
  u.reputation,
  (u.up_votes - u.down_votes) AS net_votes,
  COALESCE(bt.badge_cnt, 0)   AS badge_count
FROM qualifying_questions AS qq
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON u.id = qq.owner_user_id
LEFT JOIN badge_totals AS bt
  ON bt.user_id = u.id
ORDER BY
  qq.body_len DESC,           -- longest bodies first
  qq.id        DESC           -- tie‑breaker
LIMIT 10;