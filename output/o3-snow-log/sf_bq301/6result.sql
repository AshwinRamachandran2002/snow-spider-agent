SELECT
    ans."id"                              AS "ANSWER_ID",
    ans_user."reputation"                 AS "ANSWERER_REPUTATION",
    ans."score"                           AS "ANSWER_SCORE",
    ans."comment_count"                   AS "ANSWER_COMMENT_COUNT",
    q."tags"                              AS "QUESTION_TAGS",
    q."score"                             AS "QUESTION_SCORE",
    q."answer_count"                      AS "QUESTION_ANSWER_COUNT",
    ask_user."reputation"                 AS "ASKER_REPUTATION",
    q."view_count"                        AS "QUESTION_VIEW_COUNT",
    q."comment_count"                     AS "QUESTION_COMMENT_COUNT"
FROM  STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS  q
JOIN  STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS    ans
         ON ans."id" = q."accepted_answer_id"
JOIN  STACKOVERFLOW.STACKOVERFLOW.USERS            ans_user
         ON ans_user."id" = ans."owner_user_id"
JOIN  STACKOVERFLOW.STACKOVERFLOW.USERS            ask_user
         ON ask_user."id" = q."owner_user_id"
WHERE
      q."creation_date"  >= 1451606400000000          -- 2016-01-01 00:00:00
  AND q."creation_date"  <  1454284800000000          -- 2016-02-01 00:00:00
  AND ans."creation_date" >= 1451606400000000
  AND ans."creation_date" <  1454284800000000
  AND LOWER(q."tags") LIKE '%javascript%'
  AND (
         LOWER(q."tags") LIKE '%xss%'
      OR LOWER(q."tags") LIKE '%cross-site%'
      OR LOWER(q."tags") LIKE '%exploit%'
      OR LOWER(q."tags") LIKE '%cybersecurity%'
      );