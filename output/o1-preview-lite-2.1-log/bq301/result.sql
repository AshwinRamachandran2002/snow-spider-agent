SELECT
  a.id AS answer_id,
  ua.reputation AS answerer_reputation,
  a.score AS answer_score,
  a.comment_count AS answer_comment_count,
  q.tags AS question_tags,
  q.score AS question_score,
  q.answer_count AS question_answer_count,
  uq.reputation AS asker_reputation,
  q.view_count AS question_view_count,
  q.comment_count AS question_comment_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions` q
JOIN
  `bigquery-public-data.stackoverflow.posts_answers` a
  ON a.id = q.accepted_answer_id
LEFT JOIN
  `bigquery-public-data.stackoverflow.users` ua
  ON ua.id = a.owner_user_id
LEFT JOIN
  `bigquery-public-data.stackoverflow.users` uq
  ON uq.id = q.owner_user_id
WHERE
  q.creation_date BETWEEN '2016-01-01' AND '2016-01-31'
  AND 'javascript' IN UNNEST(SPLIT(LOWER(IFNULL(q.tags, '')), '|'))
  AND (
    'xss' IN UNNEST(SPLIT(LOWER(IFNULL(q.tags, '')), '|'))
    OR 'cross-site-scripting' IN UNNEST(SPLIT(LOWER(IFNULL(q.tags, '')), '|'))
    OR 'exploit' IN UNNEST(SPLIT(LOWER(IFNULL(q.tags, '')), '|'))
    OR 'cybersecurity' IN UNNEST(SPLIT(LOWER(IFNULL(q.tags, '')), '|'))
  );