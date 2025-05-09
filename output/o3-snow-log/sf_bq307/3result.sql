WITH "first_gold" AS (
    /* earliest gold badge each user earned */
    SELECT
        b."user_id",
        b."name"        AS "first_gold_name",
        b."date"        AS "first_gold_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    INNER JOIN (
        SELECT
            "user_id",
            MIN("date") AS "first_gold_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
        WHERE "class" = 1                      -- gold badges only
        GROUP BY "user_id"
    ) fg
    ON  fg."user_id" = b."user_id"
    AND fg."first_gold_date" = b."date"
    WHERE b."class" = 1                        -- gold badges only
)
SELECT
    fg."first_gold_name"                                                  AS "badge_name",
    COUNT(*)                                                              AS "users_first_gold",
    AVG( (fg."first_gold_date" - u."creation_date") / 86400000000.0 )     AS "avg_days_to_first_gold"
FROM "first_gold" fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON u."id" = fg."user_id"
GROUP BY fg."first_gold_name"
ORDER BY "users_first_gold" DESC NULLS LAST
LIMIT 10;