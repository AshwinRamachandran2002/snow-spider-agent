SELECT
  a.id                         AS answer_id,
  ua.reputation                AS answerer_reputation,
  a.score                      AS answer_score,
  a.comment_count              AS answer_comment_count,
  q.tags,
  q.score                      AS question_score,
  q.answer_count,
  uq.reputation                AS asker_reputation,
  q.view_count,
  q.comment_count              AS question_comment_count
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
     ON a.id = q.accepted_answer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users`     AS ua
     ON ua.id = a.owner_user_id          -- answerer
LEFT JOIN `bigquery-public-data.stackoverflow.users`     AS uq
     ON uq.id = q.owner_user_id          -- asker
WHERE q.creation_date BETWEEN '2016-01-01' AND '2016-01-31'
  AND a.creation_date BETWEEN '2016-01-01' AND '2016-01-31'
  AND LOWER(q.tags) LIKE '%javascript%'
  AND (
        LOWER(q.tags) LIKE '%xss%'          OR
        LOWER(q.tags) LIKE '%cross-site%'   OR
        LOWER(q.tags) LIKE '%exploit%'      OR
        LOWER(q.tags) LIKE '%cybersecurity%'
      )
ORDER BY a.score DESC,
         a.id;