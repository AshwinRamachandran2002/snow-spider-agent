WITH first_gold AS (
    SELECT
        b."user_id",
        b."name"                          AS "badge_name",
        b."date"                          AS "badge_date_micro",
        u."creation_date"                 AS "user_creation_micro",
        ROW_NUMBER() OVER (
            PARTITION BY b."user_id"
            ORDER BY b."date" ASC, b."id" ASC
        )                                 AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"  b
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"   u
      ON b."user_id" = u."id"
    WHERE b."class" = 1                -- gold badges only
)
SELECT
    "badge_name"                                               AS "BADGE_NAME",
    COUNT(*)                                                   AS "USERS_FIRST_GOLD_BADGE",
    ROUND(AVG( ("badge_date_micro" - "user_creation_micro")
               / 1000000 / 60 / 60 / 24 ), 4)                  AS "AVG_DAYS_TO_FIRST_GOLD"
FROM first_gold
WHERE "rn" = 1                    -- keep only the first gold badge per user
GROUP BY "badge_name"
ORDER BY "USERS_FIRST_GOLD_BADGE" DESC NULLS LAST,
         "badge_name"
LIMIT 10;