WITH first_gold AS (
    SELECT
        b."user_id",
        b."name"  AS "badge_name",
        b."date"  AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE b."class" = 1                       -- gold badges only
)

SELECT
    fg."badge_name",
    COUNT(*)                                                    AS "users_with_this_as_first_gold",
    AVG( (fg."badge_date" - u."creation_date") / 86400000000.0) AS "avg_days_from_creation"
FROM first_gold fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON fg."user_id" = u."id"
WHERE fg."rn" = 1                                               -- keep each user's first gold badge
GROUP BY fg."badge_name"
ORDER BY "users_with_this_as_first_gold" DESC NULLS LAST
LIMIT 10;