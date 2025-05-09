WITH first_gold AS (
    SELECT
        b."name",
        b."date",
        u."creation_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS  u
          ON b."user_id" = u."id"
    WHERE b."class" = 1
    QUALIFY b."date" = MIN(b."date") OVER (PARTITION BY b."user_id")   -- first gold badge per user
)
SELECT
    "name"                                                    AS "badge_name",
    COUNT(*)                                                  AS "users_first_gold",
    ROUND(
        AVG( ("date" - "creation_date") / 86400000000::FLOAT ),
        4
    )                                                        AS "avg_days_to_badge"
FROM first_gold
GROUP BY "name"
ORDER BY "users_first_gold" DESC NULLS LAST, "badge_name"
FETCH 10;