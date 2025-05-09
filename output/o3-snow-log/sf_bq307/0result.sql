WITH first_gold AS (
    SELECT
        b."user_id",
        b."name"        AS "badge_name",
        b."date"        AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE b."class" = 1                      -- gold badges only
),
first_gold_per_user AS (
    SELECT
        fg."user_id",
        fg."badge_name",
        fg."badge_date"
    FROM first_gold fg
    WHERE fg.rn = 1                          -- keep each user's first gold badge
),
elapsed AS (
    SELECT
        f."badge_name",
        (f."badge_date" - u."creation_date") / 86400000000.0 AS "days_to_badge"
    FROM first_gold_per_user f
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
          ON u."id" = f."user_id"
)
SELECT
    "badge_name",
    COUNT(*)                 AS "users_first_gold",
    AVG("days_to_badge")     AS "avg_days_account_to_badge"
FROM elapsed
GROUP BY "badge_name"
ORDER BY "users_first_gold" DESC NULLS LAST
LIMIT 10;