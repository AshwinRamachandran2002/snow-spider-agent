SELECT
  a."id" AS "answer_id",
  u_answerer."reputation" AS "answerer_reputation",
  a."score" AS "answer_score",
  a."comment_count" AS "answer_comment_count",
  q."tags" AS "question_tags",
  q."score" AS "question_score",
  q."answer_count" AS "question_answer_count",
  u_asker."reputation" AS "asker_reputation",
  q."view_count" AS "question_view_count",
  q."comment_count" AS "question_comment_count"
FROM
  STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS AS q
INNER JOIN
  STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS AS a
    ON q."accepted_answer_id" = a."id"
INNER JOIN
  STACKOVERFLOW.STACKOVERFLOW.USERS AS u_answerer
    ON a."owner_user_id" = u_answerer."id"
INNER JOIN
  STACKOVERFLOW.STACKOVERFLOW.USERS AS u_asker
    ON q."owner_user_id" = u_asker."id"
WHERE
  q."creation_date" BETWEEN 1451606400000000 AND 1454284799000000
  AND (
    q."tags" ILIKE '%javascript%'
    OR q."tags" ILIKE '%security%'
    OR q."tags" ILIKE '%xss%'
    OR q."tags" ILIKE '%cross-site-scripting%'
    OR q."tags" ILIKE '%exploit%'
    OR q."tags" ILIKE '%cybersecurity%'
  );