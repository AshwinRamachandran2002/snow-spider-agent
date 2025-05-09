SELECT 
    "user_id",
    "tags"
FROM (
        /* questions authored by the user */
        SELECT 
            pq."owner_user_id"                   AS "user_id",
            pq."tags"                            AS "tags",
            pq."creation_date"                   AS "creation_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
        
        UNION ALL
        
        /* answers authored by the user */
        SELECT 
            pa."owner_user_id"                   AS "user_id",
            q."tags"                             AS "tags",
            pa."creation_date"                   AS "creation_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS pa
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
              ON pa."parent_id" = q."id"
              
        UNION ALL
        
        /* comments made directly on questions */
        SELECT 
            c."user_id"                          AS "user_id",
            q."tags"                             AS "tags",
            c."creation_date"                    AS "creation_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.COMMENTS c
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
              ON c."post_id" = q."id"
              
        UNION ALL
        
        /* comments made on answers (need the parent question’s tags) */
        SELECT 
            c."user_id"                          AS "user_id",
            q."tags"                             AS "tags",
            c."creation_date"                    AS "creation_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.COMMENTS c
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
              ON c."post_id" = a."id"
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
              ON a."parent_id" = q."id"
) AS all_contributions
WHERE 
      "user_id" BETWEEN 16712208 AND 18712208
  AND TO_TIMESTAMP("creation_date" / 1000000) >= '2019-07-01'
  AND TO_TIMESTAMP("creation_date" / 1000000) <  '2020-01-01';