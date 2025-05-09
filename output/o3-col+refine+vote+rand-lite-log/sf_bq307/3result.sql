WITH gold_badges AS (   -- all gold-class badges
    SELECT
        "user_id",
        "name",
        "date",
        ROW_NUMBER() OVER (PARTITION BY "user_id"
                           ORDER BY "date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1
),

first_gold AS (         -- each user’s first gold badge only
    SELECT
        "user_id",
        "name"  AS "badge_name",
        "date"  AS "badge_date"
    FROM gold_badges
    WHERE "rn" = 1
),

datediffs AS (          -- days between account creation and that badge
    SELECT
        fg."badge_name",
        (fg."badge_date" - u."creation_date") / 1000000.0 / 86400.0
            AS "days_to_badge"
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON u."id" = fg."user_id"
)

SELECT
    "badge_name",
    COUNT(*)                   AS "num_users_first_gold",
    AVG("days_to_badge")       AS "avg_days_user_to_badge"
FROM datediffs
GROUP BY "badge_name"
ORDER BY "num_users_first_gold" DESC NULLS LAST
LIMIT 10;