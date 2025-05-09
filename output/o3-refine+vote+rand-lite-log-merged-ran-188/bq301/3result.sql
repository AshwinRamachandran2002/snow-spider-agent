WITH questions AS (
  SELECT
    q.id,
    q.accepted_answer_id,
    q.tags,
    q.score,
    q.answer_count,
    q.comment_count,
    q.view_count,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  WHERE
        q.creation_date >= '2016-01-01' AND q.creation_date < '2016-02-01'
    AND q.accepted_answer_id IS NOT NULL
    -- question must contain 'javascript'
    AND EXISTS (
          SELECT 1
          FROM UNNEST(SPLIT(LOWER(q.tags), '|')) AS tag
          WHERE tag = 'javascript'
        )
    -- …and at least one security–related tag
    AND EXISTS (
          SELECT 1
          FROM UNNEST(SPLIT(LOWER(q.tags), '|')) AS tag
          WHERE tag IN ('xss', 'cross-site', 'exploit', 'cybersecurity')
        )
)
SELECT
  a.id            AS answer_id,
  ua.reputation   AS answerer_reputation,
  a.score         AS answer_score,
  a.comment_count AS answer_comment_count,
  q.tags          AS question_tags,
  q.score         AS question_score,
  q.answer_count  AS question_answer_count,
  uq.reputation   AS asker_reputation,
  q.view_count    AS question_view_count,
  q.comment_count AS question_comment_count
FROM questions AS q
JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON a.id = q.accepted_answer_id
     AND a.creation_date >= '2016-01-01' AND a.creation_date < '2016-02-01'
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS uq
  ON uq.id = q.owner_user_id
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS ua
  ON ua.id = a.owner_user_id;