SELECT  "user_id",
        "tags"
FROM   (

        /* users’ own questions */
        SELECT  q."owner_user_id"                      AS "user_id",
                q."tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
        WHERE   q."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   TO_TIMESTAMP_LTZ(q."creation_date" / 1000000)
                BETWEEN '2019-07-01' AND '2019-12-31 23:59:59.999'

        UNION ALL

        /* answers they posted – inherit tags from parent question */
        SELECT  a."owner_user_id"                      AS "user_id",
                q."tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"    a
        JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
               ON q."id" = a."parent_id"
        WHERE   a."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   TO_TIMESTAMP_LTZ(a."creation_date" / 1000000)
                BETWEEN '2019-07-01' AND '2019-12-31 23:59:59.999'

        UNION ALL

        /* comments made directly on questions */
        SELECT  c."user_id",
                q."tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."COMMENTS"         c
        JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
               ON q."id" = c."post_id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   TO_TIMESTAMP_LTZ(c."creation_date" / 1000000)
                BETWEEN '2019-07-01' AND '2019-12-31 23:59:59.999'

        UNION ALL

        /* comments made on answers – inherit tags from the answer’s question */
        SELECT  c."user_id",
                q."tags"
        FROM    STACKOVERFLOW.STACKOVERFLOW."COMMENTS"         c
        JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"    a
               ON a."id" = c."post_id"
        JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
               ON q."id" = a."parent_id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   TO_TIMESTAMP_LTZ(c."creation_date" / 1000000)
                BETWEEN '2019-07-01' AND '2019-12-31 23:59:59.999'

      ) AS contributions;