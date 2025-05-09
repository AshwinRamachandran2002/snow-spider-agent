-- Accepted-answer stats for JavaScript questions (with security-related tags) asked and answered in Jan-2016
SELECT
  a.id              AS answer_id,
  ans_u.reputation  AS answerer_reputation,
  a.score           AS answer_score,
  a.comment_count   AS answer_comment_count,

  q.tags            AS question_tags,
  q.score           AS question_score,
  q.answer_count,
  ask_u.reputation  AS asker_reputation,
  q.view_count,
  q.comment_count   AS question_comment_count
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
     ON q.accepted_answer_id = a.id
LEFT JOIN `bigquery-public-data.stackoverflow.users`     AS ans_u
     ON a.owner_user_id = ans_u.id
LEFT JOIN `bigquery-public-data.stackoverflow.users`     AS ask_u
     ON q.owner_user_id = ask_u.id
WHERE q.accepted_answer_id IS NOT NULL
  -- question created in January 2016
  AND q.creation_date >= '2016-01-01'
  AND q.creation_date <  '2016-02-01'
  -- answer also posted in January 2016
  AND a.creation_date >= '2016-01-01'
  AND a.creation_date <  '2016-02-01'
  -- tag filters
  AND LOWER(q.tags) LIKE '%javascript%'
  AND (
        LOWER(q.tags) LIKE '%xss%'          OR
        LOWER(q.tags) LIKE '%cross-site%'   OR
        LOWER(q.tags) LIKE '%exploit%'      OR
        LOWER(q.tags) LIKE '%cybersecurity%'
      );