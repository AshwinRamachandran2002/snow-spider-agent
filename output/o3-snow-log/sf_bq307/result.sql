WITH gold_badges AS (   -- all gold-class badges
    SELECT
        "user_id",
        "name",
        "date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1
),
first_gold_per_user AS (      -- earliest gold badge date per user
    SELECT
        "user_id",
        MIN("date") AS "first_gold_date"
    FROM gold_badges
    GROUP BY "user_id"
),
first_gold_details AS (       -- badge name at that earliest date
    SELECT
        g."user_id",
        g."name"     AS "badge_name",
        g."date"     AS "first_gold_date"
    FROM gold_badges        g
    JOIN first_gold_per_user f
          ON g."user_id" = f."user_id"
         AND g."date"    = f."first_gold_date"
)
SELECT
    d."badge_name",
    COUNT(*)                                                   AS "users_with_as_first_gold",
    AVG( (d."first_gold_date" - u."creation_date") / 86400000000 ) 
                                                               AS "avg_days_to_first_gold"
FROM first_gold_details                d
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON u."id" = d."user_id"
GROUP BY d."badge_name"
ORDER BY "users_with_as_first_gold" DESC NULLS LAST
LIMIT 10;