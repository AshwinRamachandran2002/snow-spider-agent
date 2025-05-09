SELECT u."display_name"
FROM STACKOVERFLOW.STACKOVERFLOW.USERS              AS u
JOIN (
        SELECT "owner_user_id",
               COUNT(*) AS answer_count
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
        WHERE "owner_user_id" IS NOT NULL
        GROUP BY "owner_user_id"
     )                                              AS a
  ON u."id" = a."owner_user_id"
WHERE u."reputation" > 10
ORDER BY a.answer_count DESC NULLS LAST
LIMIT 1;