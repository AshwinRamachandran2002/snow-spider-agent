SELECT
    u."display_name"
FROM
    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"   a
JOIN
    STACKOVERFLOW.STACKOVERFLOW."USERS"           u
      ON a."owner_user_id" = u."id"
WHERE
    u."reputation" > 10
GROUP BY
    u."id",
    u."display_name"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 1;