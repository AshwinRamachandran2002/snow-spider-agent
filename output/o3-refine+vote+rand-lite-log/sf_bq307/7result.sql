WITH gold_badges AS (               -- all gold‑class badges
    SELECT
        "user_id",
        "name",
        "date",
        ROW_NUMBER() OVER (PARTITION BY "user_id"
                           ORDER BY "date", "id") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"
    WHERE "class" = 1                            -- 1 = gold
),
first_gold_badges AS (            -- each user's first gold badge(s)
    SELECT
        "user_id",
        "name",
        "date"
    FROM gold_badges
    WHERE rn = 1
),
badge_stats AS (                  -- aggregate figures
    SELECT
        f."name"                                             AS badge_name,
        COUNT(*)                                             AS users_count,
        AVG( (f."date" - u."creation_date") / 86400000000.0) AS avg_days_to_badge
    FROM first_gold_badges f
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
      ON f."user_id" = u."id"
    GROUP BY f."name"
)
SELECT
    badge_name,
    users_count,
    avg_days_to_badge
FROM badge_stats
ORDER BY users_count DESC NULLS LAST, badge_name
LIMIT 10;