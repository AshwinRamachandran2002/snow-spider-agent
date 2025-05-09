-- top‑10 longest SO questions that either
--   • already have an accepted answer, or
--   • (no accepted answer) but possess ≥1 answer whose
--     score / question‑views  > 0.01
-- plus information about the asker's reputation,
-- net votes and badge count
WITH qualified_questions AS (
  SELECT
    q.id,
    q.body,
    q.owner_user_id,
    q.view_count,
    LENGTH(q.body)            AS body_length
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        q.accepted_answer_id IS NOT NULL                -- has accepted answer
    OR  q.id IN (                                        -- otherwise: high‑ratio answer
          SELECT DISTINCT a.parent_id
          FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
          JOIN `bigquery-public-data.stackoverflow.posts_questions` AS qq
                ON qq.id = a.parent_id
          WHERE qq.accepted_answer_id IS NULL
            AND qq.view_count IS NOT NULL
            AND qq.view_count > 0
            AND a.score / CAST(qq.view_count AS FLOAT64) > 0.01
        )
),
top_questions AS (        -- longest 10 bodies
  SELECT *
  FROM qualified_questions
  ORDER BY body_length DESC, id
  LIMIT 10
),
user_info AS (            -- askers’ reputation & net votes
  SELECT
    u.id                            AS user_id,
    u.reputation,
    u.up_votes - u.down_votes       AS net_votes
  FROM `bigquery-public-data.stackoverflow.users` AS u
),
badge_counts AS (         -- total badges per user
  SELECT
    user_id,
    COUNT(*) AS total_badges
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  tq.id                AS question_id,
  tq.body_length,
  ui.reputation,
  ui.net_votes,
  IFNULL(bc.total_badges,0) AS total_badges
FROM top_questions           AS tq
LEFT JOIN user_info   AS ui  ON ui.user_id = tq.owner_user_id
LEFT JOIN badge_counts AS bc ON bc.user_id = tq.owner_user_id
ORDER BY tq.body_length DESC, tq.id;