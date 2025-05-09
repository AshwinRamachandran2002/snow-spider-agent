WITH first_gold_per_user AS (          -- every (user, gold badge) with its first‑earned date
    SELECT
        b."user_id",
        b."name"                AS "badge_name",
        MIN(b."date")           AS "first_gold_date"
    FROM   STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE  b."class" = 1                    -- gold badges only
    GROUP  BY b."user_id", b."name"
),
ranked AS (                               -- rank gold badges chronologically per user
    SELECT
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f."user_id"
                           ORDER BY f."first_gold_date") AS "rn"
    FROM   first_gold_per_user f
),
first_gold_only AS (                      -- keep only the very first gold badge per user
    SELECT
        "user_id",
        "badge_name",
        "first_gold_date"
    FROM   ranked
    WHERE  "rn" = 1
)
SELECT
    fg."badge_name",
    COUNT(*)                                                  AS "users_with_this_first_gold",
    AVG( (fg."first_gold_date" - u."creation_date") / 86400000000.0 )
        AS "avg_days_to_first_gold"
FROM   first_gold_only fg
JOIN   STACKOVERFLOW.STACKOVERFLOW.USERS u
       ON fg."user_id" = u."id"
GROUP  BY fg."badge_name"
ORDER  BY "users_with_this_first_gold" DESC NULLS LAST,
          fg."badge_name"
LIMIT  10;