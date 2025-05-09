WITH FIRST_GOLD AS (
    SELECT
        b."user_id",
        b."name"  AS "badge_name",
        b."date"  AS "badge_date",
        ROW_NUMBER() OVER (
            PARTITION BY b."user_id"
            ORDER BY b."date" ASC, b."name" ASC
        ) AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE b."class" = 1               -- gold badges
)
SELECT
    fg."badge_name"                                   AS "BADGE_NAME",
    COUNT(*)                                          AS "USER_COUNT",
    ROUND(AVG( (fg."badge_date" - u."creation_date") / 1000000.0 / 86400 ), 4)
                                                     AS "AVG_DAYS_TO_BADGE"
FROM FIRST_GOLD fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
     ON fg."user_id" = u."id"
WHERE fg."rn" = 1                                     -- keep only the first gold badge per user
GROUP BY fg."badge_name"
ORDER BY "USER_COUNT" DESC NULLS LAST, "BADGE_NAME" ASC
LIMIT 10;