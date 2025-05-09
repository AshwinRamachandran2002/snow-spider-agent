-- 10 longest “qualifying” questions together with the asker's
-- reputation, net-votes and badge count
WITH
-- questions that (so far) do NOT have an accepted answer but
-- do have at least one answer whose score / view-count > 0.01
ratio_q AS (
  SELECT DISTINCT q.id
  FROM `bigquery-public-data.stackoverflow.posts_questions`  AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
    ON a.parent_id = q.id
  WHERE q.accepted_answer_id IS NULL          -- no accepted answer
    AND q.view_count > 0                      -- avoid div-by-0
    AND a.score / CAST(q.view_count AS FLOAT64) > 0.01
),

-- all questions we want to consider
qual_q AS (
  SELECT *
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE accepted_answer_id IS NOT NULL        -- has accepted answer
     OR id IN (SELECT id FROM ratio_q)        -- …or passes ratio test
),

-- badge totals per user
badge_tot AS (
  SELECT user_id, COUNT(*) AS badge_cnt
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
),

-- combine user reputation, net votes, and badge count
user_stats AS (
  SELECT
    u.id                                   AS user_id,
    u.reputation,
    u.up_votes - u.down_votes              AS net_votes,
    COALESCE(b.badge_cnt, 0)               AS badge_cnt
  FROM `bigquery-public-data.stackoverflow.users` AS u
  LEFT JOIN badge_tot AS b
    ON u.id = b.user_id
)

SELECT
  q.id                         AS question_id,
  LENGTH(q.body)               AS body_length,
  COALESCE(us.reputation, 0)   AS reputation,
  COALESCE(us.net_votes, 0)    AS net_votes,
  COALESCE(us.badge_cnt, 0)    AS badge_cnt
FROM   qual_q       AS q
LEFT JOIN user_stats AS us
  ON us.user_id = q.owner_user_id
ORDER BY body_length DESC
LIMIT 10;