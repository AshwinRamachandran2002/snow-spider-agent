WITH questions AS (
  SELECT
    q.id,
    q.body,
    LENGTH(q.body)        AS body_length,
    q.view_count,
    q.accepted_answer_id,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.body IS NOT NULL
),
qualified AS (
  -- keep questions that satisfy either of the two stated requirements
  SELECT *
  FROM questions AS q
  WHERE
        -- case 1 : has an accepted answer
        q.accepted_answer_id IS NOT NULL

     OR -- case 2 : no accepted answer but at least one “good” answer
        (
          q.accepted_answer_id IS NULL
          AND q.view_count > 0
          AND EXISTS (
              SELECT 1
              FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
              WHERE a.parent_id = q.id
                AND (a.score / q.view_count) > 0.01          -- score‑to‑view ratio
          )
        )
),
top10 AS (
  SELECT *
  FROM qualified
  ORDER BY body_length DESC, id
  LIMIT 10
),
user_stats AS (
  SELECT
    u.id                                         AS user_id,
    u.reputation,
    (u.up_votes - u.down_votes)                 AS net_votes
  FROM `bigquery-public-data.stackoverflow.users` AS u
),
badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  t.id                                AS question_id,
  t.body_length,
  us.reputation,
  us.net_votes,
  COALESCE(bc.badge_count, 0)         AS badge_count
FROM top10           AS t
LEFT JOIN user_stats AS us ON us.user_id = t.owner_user_id
LEFT JOIN badge_counts AS bc ON bc.user_id = t.owner_user_id
ORDER BY t.body_length DESC, t.id;