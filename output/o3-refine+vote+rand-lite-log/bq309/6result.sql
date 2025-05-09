WITH badge_counts AS (
  SELECT
    user_id,
    COUNT(1) AS badge_count
  FROM
    `bigquery-public-data.stackoverflow.badges`
  GROUP BY
    user_id
)
SELECT
  q.id                                AS question_id,
  LENGTH(q.body)                      AS body_length,
  u.reputation                        AS user_reputation,
  (u.up_votes - u.down_votes)         AS user_net_votes,
  COALESCE(b.badge_count, 0)          AS user_badge_total
FROM
  `bigquery-public-data.stackoverflow.posts_questions` AS q
JOIN
  `bigquery-public-data.stackoverflow.users`           AS u
    ON u.id = q.owner_user_id
LEFT JOIN
  badge_counts                                         AS b
    ON b.user_id = u.id
WHERE
      q.accepted_answer_id IS NOT NULL                      -- condition 1
   OR ( q.accepted_answer_id IS NULL                        -- condition 2
        AND q.view_count > 0
        AND EXISTS (
              SELECT 1
              FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
              WHERE  a.parent_id = q.id
                 AND a.score / CAST(q.view_count AS FLOAT64) > 0.01
            )
      )
ORDER BY
  body_length DESC,
  question_id
LIMIT 10;