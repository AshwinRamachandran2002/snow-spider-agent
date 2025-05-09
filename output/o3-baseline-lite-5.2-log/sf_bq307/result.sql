WITH "FIRST_GOLD" AS (
    SELECT
        b."user_id",
        b."name"                            AS "badge_name",
        b."date"                            AS "badge_date",
        u."creation_date"                   AS "user_creation_date",
        ROW_NUMBER() OVER (
            PARTITION BY b."user_id"
            ORDER BY b."date", b."id"
        )                                   AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"  u
          ON b."user_id" = u."id"
    WHERE b."class" = 1                           -- gold badges only
    QUALIFY rn = 1                                -- each user's first gold badge
)

SELECT
    "badge_name"                                            AS "badge_name",
    COUNT(*)                                                AS "users_earning_it_first",
    AVG( ("badge_date" - "user_creation_date")
         / 86400000000.0 )                                  AS "avg_days_to_first_gold"
FROM "FIRST_GOLD"
GROUP BY "badge_name"
ORDER BY "users_earning_it_first" DESC, "badge_name"
LIMIT 10;