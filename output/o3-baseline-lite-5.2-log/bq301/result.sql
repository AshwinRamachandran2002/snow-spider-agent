SELECT
  a.id                                             AS answer_id,
  ans_u.reputation                                 AS answerer_reputation,
  a.score                                          AS answer_score,
  a.comment_count                                  AS answer_comment_count,
  q.tags                                           AS question_tags,
  q.score                                          AS question_score,
  q.answer_count                                   AS question_answer_count,
  ask_u.reputation                                 AS asker_reputation,
  q.view_count                                     AS question_view_count,
  q.comment_count                                  AS question_comment_count
FROM `bigquery-public-data.stackoverflow.posts_questions`        AS q
JOIN `bigquery-public-data.stackoverflow.posts_answers`          AS a
      ON a.id = q.accepted_answer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users`             AS ask_u
      ON ask_u.id = q.owner_user_id
LEFT JOIN `bigquery-public-data.stackoverflow.users`             AS ans_u
      ON ans_u.id = a.owner_user_id
WHERE
      -- question created in January 2016
      q.creation_date >= TIMESTAMP('2016-01-01')
  AND q.creation_date <  TIMESTAMP('2016-02-01')
      -- accepted answer also created in January 2016
  AND a.creation_date >= TIMESTAMP('2016-01-01')
  AND a.creation_date <  TIMESTAMP('2016-02-01')
      -- tag requirements
  AND q.tags IS NOT NULL
  AND REGEXP_CONTAINS(q.tags, r'(^|[|])javascript($|[|])')
  AND (
         REGEXP_CONTAINS(q.tags, r'(^|[|])xss($|[|])')
      OR REGEXP_CONTAINS(q.tags, r'(^|[|])cross-site($|[|])')
      OR REGEXP_CONTAINS(q.tags, r'(^|[|])exploit($|[|])')
      OR REGEXP_CONTAINS(q.tags, r'(^|[|])cybersecurity($|[|])')
  );