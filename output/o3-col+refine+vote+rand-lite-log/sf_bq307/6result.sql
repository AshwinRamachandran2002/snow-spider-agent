WITH first_gold AS (
    SELECT
        b."user_id",
        b."name"        AS "badge_name",
        b."date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    WHERE b."class" = 1                             -- gold badges only
),
first_gold_per_user AS (
    SELECT
        "user_id",
        "badge_name",
        "date"
    FROM first_gold
    WHERE "rn" = 1                                  -- keep only the very first gold badge per user
)
SELECT
    fg."badge_name",
    COUNT(*)                                                  AS "users_first_gold",
    ROUND(AVG( (fg."date" - u."creation_date") / 86400000000 ), 4)  AS "avg_days_to_earn"
FROM first_gold_per_user fg
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
  ON fg."user_id" = u."id"
GROUP BY fg."badge_name"
ORDER BY "users_first_gold" DESC NULLS LAST
LIMIT 10;