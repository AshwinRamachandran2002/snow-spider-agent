WITH questions AS (
  SELECT
    id                              AS question_id,
    accepted_answer_id,
    tags                            AS question_tags,
    score                           AS question_score,
    answer_count                    AS question_answer_count,
    comment_count                   AS question_comment_count,
    view_count                      AS question_view_count,
    owner_user_id                   AS asker_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
        creation_date >= '2016-01-01' AND creation_date < '2016-02-01'
    AND accepted_answer_id IS NOT NULL
    -- tag list is stored pipe‑delimited (e.g. "javascript|xss")
    AND 'javascript' IN UNNEST(SPLIT(tags,'|'))
    AND EXISTS (
          SELECT 1
          FROM UNNEST(SPLIT(tags,'|')) tag
          WHERE tag IN ('xss','cross-site','cross-site-scripting','exploit','cybersecurity')
        )
),
answers AS (
  SELECT
    id                AS answer_id,
    owner_user_id     AS answerer_id,
    score             AS answer_score,
    comment_count     AS answer_comment_count
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE
        creation_date >= '2016-01-01' AND creation_date < '2016-02-01'
)
SELECT
  a.answer_id,
  IFNULL(ans_u.reputation,0)          AS answerer_reputation,
  a.answer_score,
  a.answer_comment_count,
  q.question_tags,
  q.question_score,
  q.question_answer_count,
  IFNULL(ask_u.reputation,0)          AS asker_reputation,
  q.question_view_count,
  q.question_comment_count
FROM questions q
JOIN answers   a   ON a.answer_id = q.accepted_answer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users` ans_u ON ans_u.id = a.answerer_id
LEFT JOIN `bigquery-public-data.stackoverflow.users` ask_u ON ask_u.id = q.asker_id;