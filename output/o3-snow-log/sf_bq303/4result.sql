SELECT  USER_ID ,
        TAGS
FROM   (

        /* 1. questions authored by the user */
        SELECT  q."owner_user_id" AS USER_ID ,
                q."tags"          AS TAGS
        FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
        WHERE   q."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   q."creation_date" BETWEEN 1561939200000000   -- 2019-07-01
                                     AND 1577836799000000   -- 2019-12-31

        UNION ALL

        /* 2. answers authored by the user (parent question supplies tags) */
        SELECT  a."owner_user_id" AS USER_ID ,
                pq."tags"         AS TAGS
        FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS   a
        JOIN    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
               ON a."parent_id" = pq."id"
        WHERE   a."owner_user_id" BETWEEN 16712208 AND 18712208
          AND   a."creation_date" BETWEEN 1561939200000000
                                     AND 1577836799000000

        UNION ALL

        /* 3a. comments written by the user that are on questions */
        SELECT  c."user_id"       AS USER_ID ,
                pq."tags"         AS TAGS
        FROM    STACKOVERFLOW.STACKOVERFLOW.COMMENTS        c
        JOIN    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
               ON c."post_id" = pq."id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   c."creation_date" BETWEEN 1561939200000000
                                     AND 1577836799000000

        UNION ALL

        /* 3b. comments written by the user that are on answers */
        SELECT  c."user_id"       AS USER_ID ,
                pq."tags"         AS TAGS
        FROM    STACKOVERFLOW.STACKOVERFLOW.COMMENTS       c
        JOIN    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS  a
               ON c."post_id" = a."id"
        JOIN    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
               ON a."parent_id" = pq."id"
        WHERE   c."user_id" BETWEEN 16712208 AND 18712208
          AND   c."creation_date" BETWEEN 1561939200000000
                                     AND 1577836799000000
) contributions;