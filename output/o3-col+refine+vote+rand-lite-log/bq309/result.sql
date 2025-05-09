-- Top-10 longest Stack Overflow questions that
--   A) already have an accepted answer, OR
--   B) have no accepted answer but do contain at least one answer whose
--      score-to-view ratio exceeds 0.01.
-- For each question return the asker's reputation, net votes and badge count.

WITH
-- questions that satisfy condition B
ratio_ok AS (
  SELECT DISTINCT a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`     AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
    ON q.id = a.parent_id
  WHERE q.accepted_answer_id IS NULL               -- no accepted answer
    AND q.view_count IS NOT NULL
    AND q.view_count > 0                           -- avoid division by zero
    AND a.score / CAST(q.view_count AS FLOAT64) > 0.01
),

-- all questions that meet either condition A or B
candidate_questions AS (
  SELECT *
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.accepted_answer_id IS NOT NULL        -- condition A
     OR q.id IN (SELECT question_id FROM ratio_ok)   -- condition B
),

-- badge counts per user
user_badges AS (
  SELECT user_id, COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  q.id                                    AS question_id,
  LENGTH(q.body)                          AS body_length,
  u.reputation,
  (u.up_votes - u.down_votes)             AS net_votes,
  IFNULL(b.badge_count, 0)                AS badge_count
FROM candidate_questions AS q
JOIN `bigquery-public-data.stackoverflow.users`  AS u
  ON u.id = q.owner_user_id
LEFT JOIN user_badges AS b
  ON b.user_id = u.id
ORDER BY body_length DESC
LIMIT 10;