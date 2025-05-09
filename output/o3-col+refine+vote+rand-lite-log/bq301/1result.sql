SELECT
  a.id                           AS answer_id,
  ua.reputation                  AS answerer_reputation,
  a.score                        AS answer_score,
  a.comment_count                AS answer_comment_count,
  q.tags                         AS question_tags,
  q.score                        AS question_score,
  q.answer_count                 AS question_answer_count,
  uq.reputation                  AS asker_reputation,
  q.view_count                   AS question_view_count,
  q.comment_count                AS question_comment_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`  AS q
JOIN
  `bigquery-public-data.stackoverflow.posts_answers`    AS a
    ON a.id = q.accepted_answer_id
LEFT JOIN
  `bigquery-public-data.stackoverflow.users`            AS uq
    ON uq.id = q.owner_user_id          -- asker
LEFT JOIN
  `bigquery-public-data.stackoverflow.users`            AS ua
    ON ua.id = a.owner_user_id          -- answerer
WHERE
  -- both the question and its accepted answer were created in Jan-2016
  q.creation_date BETWEEN '2016-01-01' AND '2016-01-31 23:59:59'
  AND a.creation_date BETWEEN '2016-01-01' AND '2016-01-31 23:59:59'
  -- question tag string must contain "javascript" and any security keyword
  AND LOWER(q.tags) LIKE '%javascript%'
  AND (
        LOWER(q.tags) LIKE '%xss%'         OR
        LOWER(q.tags) LIKE '%cross-site%'  OR
        LOWER(q.tags) LIKE '%exploit%'     OR
        LOWER(q.tags) LIKE '%cybersecurity%'
      );