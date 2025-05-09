WITH first_gold AS (
    SELECT
        "user_id",
        "name"  AS "badge_name",
        "date"  AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "date") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1                               -- gold badges only
),
first_gold_with_days AS (
    SELECT
        fg."badge_name",
        (fg."badge_date" - u."creation_date") / 86400000000.0  AS "days_to_badge"
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON fg."user_id" = u."id"
    WHERE fg.rn = 1                                 -- keep each user's first gold badge
)
SELECT
    "badge_name",
    COUNT(*)                              AS "users_first_gold_badge",
    ROUND(AVG("days_to_badge"), 4)        AS "avg_days_until_badge"
FROM first_gold_with_days
GROUP BY "badge_name"
ORDER BY "users_first_gold_badge" DESC NULLS LAST
LIMIT 10;