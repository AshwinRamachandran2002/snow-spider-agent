/*  Users’ contributions (questions, answers, comments) made between
    2019-07-01 00:00:00  and  2019-12-31 23:59:59  (UTC, micro-seconds)
    for user_ids 16712208 … 18712208, together with the tags
    of the question to which each contribution belongs             */

SELECT  "user_id",
        "tags"
FROM   (
        /* --- questions authored ------------------------------------ */
        SELECT  q."owner_user_id"        AS "user_id",
                q."tags"                 AS "tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
        WHERE   q."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   q."creation_date"  BETWEEN 1561939200000000  /* 2019-07-01 */
                                      AND 1577836799000000  /* 2019-12-31 23:59:59 */
          AND   q."tags" IS NOT NULL

        UNION ALL

        /* --- answers posted ---------------------------------------- */
        SELECT  a."owner_user_id"        AS "user_id",
                q."tags"                 AS "tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
          JOIN  STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
                ON q."id" = a."parent_id"
        WHERE   a."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   a."creation_date"  BETWEEN 1561939200000000
                                      AND 1577836799000000
          AND   q."tags" IS NOT NULL

        UNION ALL

        /* --- comments on questions --------------------------------- */
        SELECT  c."user_id"              AS "user_id",
                q."tags"                 AS "tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."COMMENTS"        c
          JOIN  STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
                ON q."id" = c."post_id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   c."creation_date" BETWEEN 1561939200000000
                                     AND 1577836799000000
          AND   q."tags" IS NOT NULL

        UNION ALL

        /* --- comments on answers ----------------------------------- */
        SELECT  c."user_id"              AS "user_id",
                q."tags"                 AS "tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."COMMENTS"        c
          JOIN  STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
                ON a."id" = c."post_id"
          JOIN  STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
                ON q."id" = a."parent_id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   c."creation_date" BETWEEN 1561939200000000
                                     AND 1577836799000000
          AND   q."tags" IS NOT NULL
      )
;