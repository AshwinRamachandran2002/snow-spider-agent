SELECT  u."display_name"
FROM   (
          SELECT  "owner_user_id",
                  COUNT(*) AS answer_cnt
          FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
          WHERE   "owner_user_id" IS NOT NULL
          GROUP BY "owner_user_id"
       ) ac
JOIN   STACKOVERFLOW.STACKOVERFLOW.USERS u
       ON u."id" = ac."owner_user_id"
WHERE  u."reputation" > 10
ORDER  BY ac.answer_cnt DESC NULLS LAST
LIMIT  1;