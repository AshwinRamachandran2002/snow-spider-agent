WITH gold_badges AS (   -- all gold-badge awards with a sequence per user
    SELECT
        "user_id",
        "name"  AS "badge_name",
        "date"  AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1                              -- gold only
),
first_gold AS (       -- keep only each user’s very first gold badge
    SELECT
        "user_id",
        "badge_name",
        "badge_date"
    FROM gold_badges
    WHERE "rn" = 1
)
SELECT
    fg."badge_name"                                    AS "badge_name",
    COUNT(*)                                           AS "users_first_gold",
    AVG( (fg."badge_date" - u."creation_date") / 86400000000.0 )
        AS "avg_days_to_first_gold"                    -- microseconds ➔ days
FROM first_gold fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON fg."user_id" = u."id"
GROUP BY fg."badge_name"
ORDER BY "users_first_gold" DESC NULLS LAST
LIMIT 10;