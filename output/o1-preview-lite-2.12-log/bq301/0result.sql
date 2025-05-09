SELECT
  a.id AS answer_id,
  u1.reputation AS answerer_reputation,
  a.score AS answer_score,
  a.comment_count AS answer_comment_count,
  q.tags AS question_tags,
  q.score AS question_score,
  q.answer_count AS question_answer_count,
  u2.reputation AS asker_reputation,
  q.view_count AS question_view_count,
  q.comment_count AS question_comment_count
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON q.accepted_answer_id = a.id
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS u1
  ON a.owner_user_id = u1.id
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS u2
  ON q.owner_user_id = u2.id
WHERE q.creation_date >= '2016-01-01'
  AND q.creation_date < '2016-02-01'
  AND EXISTS (
    SELECT 1
    FROM UNNEST(SPLIT(q.tags, '|')) AS tag
    WHERE LOWER(tag) IN ('javascript', 'xss', 'cross-site-scripting', 'security', 'cybersecurity', 'exploit')
  )