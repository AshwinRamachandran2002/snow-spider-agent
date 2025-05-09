WITH first_gold AS (
    SELECT
        b."user_id",
        b."name",
        b."date"            AS "badge_date",
        u."creation_date"   AS "user_creation_date"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."BADGES"  b
        JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"   u
              ON b."user_id" = u."id"
    WHERE
        b."class" = 1                           -- gold badges only
    QUALIFY                                      -- keep the first gold badge per user
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") = 1
)

SELECT
    "name",
    COUNT(*)                                                   AS "users_first_gold",
    ROUND(
        AVG( ("badge_date" - "user_creation_date") / 86400000000 ),
        4
    )                                                          AS "avg_days_to_first_gold"
FROM   first_gold
GROUP  BY "name"
ORDER  BY "users_first_gold" DESC NULLS LAST
LIMIT  10;