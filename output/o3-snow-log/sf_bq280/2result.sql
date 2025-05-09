SELECT 
    u."display_name"
FROM (
    SELECT 
        a."owner_user_id",
        COUNT(*) AS "answer_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    WHERE a."owner_user_id" IS NOT NULL
    GROUP BY a."owner_user_id"
) a
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
  ON a."owner_user_id" = u."id"
WHERE u."reputation" > 10
ORDER BY a."answer_cnt" DESC NULLS LAST
LIMIT 1;