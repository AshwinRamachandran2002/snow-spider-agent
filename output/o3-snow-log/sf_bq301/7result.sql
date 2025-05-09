SELECT 
    A."id"                                   AS "answer_id",
    AU."reputation"                          AS "answerer_reputation",
    A."score"                                AS "answer_score",
    A."comment_count"                        AS "answer_comment_count",
    
    Q."tags"                                 AS "question_tags",
    Q."score"                                AS "question_score",
    Q."answer_count"                         AS "question_answer_count",
    QU."reputation"                          AS "asker_reputation",
    Q."view_count"                           AS "question_view_count",
    Q."comment_count"                        AS "question_comment_count"
FROM  STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  Q
JOIN  STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"    A
      ON A."id" = Q."accepted_answer_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"        AU
      ON AU."id" = A."owner_user_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"        QU
      ON QU."id" = Q."owner_user_id"
WHERE 
      /* questions created in Jan-2016 */
      Q."creation_date" >= 1451606400000000      -- 2016-01-01 00:00:00 UTC
  AND Q."creation_date" <  1454284800000000      -- 2016-02-01 00:00:00 UTC
      
      /* accepted answers also created in Jan-2016 */
  AND A."creation_date" >= 1451606400000000
  AND A."creation_date" <  1454284800000000
      
      /* tag requirements */
  AND Q."tags" ILIKE '%javascript%'
  AND (   Q."tags" ILIKE '%xss%'
       OR Q."tags" ILIKE '%cross-site%'
       OR Q."tags" ILIKE '%exploit%'
       OR Q."tags" ILIKE '%cybersecurity%' )

      /* ensure there is an accepted answer (redundant with join, but explicit) */
  AND Q."accepted_answer_id" IS NOT NULL;