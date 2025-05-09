SELECT 
    a."id"                                AS "ANSWER_ID",
    au."reputation"                       AS "ANSWERER_REPUTATION",
    a."score"                             AS "ANSWER_SCORE",
    a."comment_count"                     AS "ANSWER_COMMENT_COUNT",
    
    q."tags"                              AS "QUESTION_TAGS",
    q."score"                             AS "QUESTION_SCORE",
    q."answer_count"                      AS "QUESTION_ANSWER_COUNT",
    qu."reputation"                       AS "ASKER_REPUTATION",
    q."view_count"                        AS "QUESTION_VIEW_COUNT",
    q."comment_count"                     AS "QUESTION_COMMENT_COUNT"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"    a
     ON a."id" = q."accepted_answer_id"
        AND TO_TIMESTAMP_LTZ(a."creation_date"/1000000)
                BETWEEN '2016-01-01'::TIMESTAMP 
                    AND '2016-01-31 23:59:59'::TIMESTAMP
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"            au
     ON au."id" = a."owner_user_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"       qu
     ON qu."id" = q."owner_user_id"
WHERE TO_TIMESTAMP_LTZ(q."creation_date"/1000000)
          BETWEEN '2016-01-01'::TIMESTAMP 
              AND '2016-01-31 23:59:59'::TIMESTAMP
  AND q."tags" ILIKE '%javascript%'
  AND (
        q."tags" ILIKE '%xss%'          OR
        q."tags" ILIKE '%cross-site%'   OR
        q."tags" ILIKE '%exploit%'      OR
        q."tags" ILIKE '%cybersecurity%'
      );