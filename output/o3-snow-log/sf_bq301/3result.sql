SELECT
    ans."id"                                   AS "answer_id",
    au."reputation"                            AS "answerer_reputation",
    ans."score"                                AS "answer_score",
    ans."comment_count"                        AS "answer_comment_count",
    q."tags"                                   AS "question_tags",
    q."score"                                  AS "question_score",
    q."answer_count"                           AS "question_answer_count",
    qu."reputation"                            AS "asker_reputation",
    q."view_count"                             AS "question_view_count",
    q."comment_count"                          AS "question_comment_count"
FROM  STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS  AS q
JOIN  STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS    AS ans
      ON ans."id" = q."accepted_answer_id"
JOIN  STACKOVERFLOW.STACKOVERFLOW.USERS            AS au
      ON au."id" = ans."owner_user_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.USERS        AS qu
      ON qu."id" = q."owner_user_id"
WHERE
      /* question posted in Jan-2016 */
      TO_TIMESTAMP(q."creation_date" / 1000000) >= '2016-01-01'
  AND TO_TIMESTAMP(q."creation_date" / 1000000) <  '2016-02-01'
      /* accepted answer posted in Jan-2016 */
  AND TO_TIMESTAMP(ans."creation_date" / 1000000) >= '2016-01-01'
  AND TO_TIMESTAMP(ans."creation_date" / 1000000) <  '2016-02-01'
      /* tag filters */
  AND LOWER(q."tags") LIKE '%javascript%'
  AND (
        LOWER(q."tags") LIKE '%xss%'          OR
        LOWER(q."tags") LIKE '%cross-site%'   OR
        LOWER(q."tags") LIKE '%exploit%'      OR
        LOWER(q."tags") LIKE '%cybersecurity%'
      );