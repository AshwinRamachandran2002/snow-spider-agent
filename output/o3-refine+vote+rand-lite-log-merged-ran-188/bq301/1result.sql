/* Accepted answers (and their questions) posted in January‑2016
   Questions must have the tag “javascript” AND at least one of
   “xss”, “cross-site”, “exploit”, or “cybersecurity”.            */

WITH filtered_questions AS (
  SELECT
    q.id                  AS question_id,
    q.accepted_answer_id,
    q.tags,
    q.score               AS question_score,
    q.answer_count,
    q.view_count,
    q.comment_count       AS question_comment_count,
    q.owner_user_id       AS asker_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  WHERE q.creation_date BETWEEN '2016-01-01' AND '2016-01-31'
    AND q.accepted_answer_id IS NOT NULL
    AND q.tags IS NOT NULL
    -- tag “javascript”
    AND REGEXP_CONTAINS(q.tags, r'(^|[|])javascript([|]|$)')
    -- plus at least one of the security‑related tags
    AND (
         REGEXP_CONTAINS(q.tags, r'(^|[|])xss([|]|$)')              OR
         REGEXP_CONTAINS(q.tags, r'(^|[|])cross-site([|]|$)')       OR
         REGEXP_CONTAINS(q.tags, r'(^|[|])exploit([|]|$)')          OR
         REGEXP_CONTAINS(q.tags, r'(^|[|])cybersecurity([|]|$)')
        )
),

accepted_answers AS (
  SELECT
    a.id            AS answer_id,
    a.parent_id     AS question_id,
    a.score         AS answer_score,
    a.comment_count AS answer_comment_count,
    a.owner_user_id AS answerer_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  WHERE a.creation_date BETWEEN '2016-01-01' AND '2016-01-31'
)

SELECT
  aa.answer_id,
  COALESCE(au.reputation, 0)           AS answerer_reputation,
  aa.answer_score,
  aa.answer_comment_count,
  fq.tags                              AS question_tags,
  fq.question_score,
  fq.answer_count,
  COALESCE(qu.reputation, 0)           AS asker_reputation,
  fq.view_count,
  fq.question_comment_count
FROM filtered_questions fq
JOIN accepted_answers   aa
  ON aa.answer_id = fq.accepted_answer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users` au
  ON au.id = aa.answerer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users` qu
  ON qu.id = fq.asker_id
ORDER BY aa.answer_id;