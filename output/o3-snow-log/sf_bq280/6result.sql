WITH answer_counts AS (
    SELECT
        "owner_user_id"                   AS "user_id",
        COUNT(*)                          AS "answer_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE "owner_user_id" IS NOT NULL
    GROUP BY "owner_user_id"
)

SELECT
    u."display_name"
FROM answer_counts ac
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
  ON u."id" = ac."user_id"
WHERE u."reputation" > 10
ORDER BY ac."answer_count" DESC NULLS LAST
LIMIT 1;