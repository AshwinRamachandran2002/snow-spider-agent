WITH answer_counts AS (
    SELECT
        pa."owner_user_id"            AS "user_id",
        COUNT(*)                      AS "answer_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" pa
    WHERE pa."owner_user_id" IS NOT NULL
    GROUP BY pa."owner_user_id"
),
eligible_users AS (
    SELECT
        u."display_name",
        ac."answer_count",
        ROW_NUMBER() OVER (ORDER BY ac."answer_count" DESC) AS rn
    FROM answer_counts ac
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
          ON u."id" = ac."user_id"
    WHERE u."reputation" > 10
)
SELECT "display_name"
FROM eligible_users
WHERE rn = 1;