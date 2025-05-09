SELECT
       PA."id"                                    AS "ANSWER_ID",
       COALESCE(UA."reputation", 0)               AS "ANSWERER_REPUTATION",
       PA."score"                                 AS "ANSWER_SCORE",
       PA."comment_count"                         AS "ANSWER_COMMENT_COUNT",

       PQ."tags"                                  AS "QUESTION_TAGS",
       PQ."score"                                 AS "QUESTION_SCORE",
       PQ."answer_count"                          AS "QUESTION_ANSWER_COUNT",
       COALESCE(UQ."reputation", 0)               AS "ASKER_REPUTATION",
       PQ."view_count"                            AS "QUESTION_VIEW_COUNT",
       PQ."comment_count"                         AS "QUESTION_COMMENT_COUNT"
FROM   STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS  PQ
JOIN   STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS    PA
           ON PA."id" = PQ."accepted_answer_id"
LEFT  JOIN STACKOVERFLOW.STACKOVERFLOW.USERS        UA
           ON UA."id" = PA."owner_user_id"
LEFT  JOIN STACKOVERFLOW.STACKOVERFLOW.USERS        UQ
           ON UQ."id" = PQ."owner_user_id"
WHERE  PQ."accepted_answer_id" IS NOT NULL
  -- Question posted in January 2016
  AND  TO_DATE(TO_TIMESTAMP(PQ."creation_date" / 1000000)) BETWEEN '2016-01-01' AND '2016-01-31'
  -- Accepted answer also posted in January 2016
  AND  TO_DATE(TO_TIMESTAMP(PA."creation_date" / 1000000)) BETWEEN '2016-01-01' AND '2016-01-31'
  -- Tag requirements: must include 'javascript' and at least one security-related tag
  AND  LOWER(PQ."tags") LIKE '%javascript%'
  AND (
        LOWER(PQ."tags") LIKE '%xss%'          OR
        LOWER(PQ."tags") LIKE '%cross-site%'   OR
        LOWER(PQ."tags") LIKE '%exploit%'      OR
        LOWER(PQ."tags") LIKE '%cybersecurity%'
      )
ORDER BY PA."score" DESC NULLS LAST;