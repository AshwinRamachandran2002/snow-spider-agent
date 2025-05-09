WITH gold_badges AS (      -- all gold badges
    SELECT
        "user_id",
        "name",
        "date"       AS "badge_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1
),
first_gold AS (            -- the first‑earned gold badge(s) per user
    SELECT
        "user_id",
        "name",
        "badge_date"
    FROM gold_badges
    QUALIFY "badge_date" = MIN("badge_date") OVER (PARTITION BY "user_id")
),
elapsed_days AS (          -- add days from account creation to badge gain
    SELECT
        fg."name"                  AS badge_name,
        fg."user_id",
        (fg."badge_date" - u."creation_date") / 86400000000.0  AS days_to_badge
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
          ON fg."user_id" = u."id"
)
SELECT
    badge_name,
    COUNT(DISTINCT "user_id")                       AS first_gold_user_count,
    ROUND(AVG(days_to_badge), 4)                    AS avg_days_until_badge
FROM elapsed_days
GROUP BY badge_name
ORDER BY first_gold_user_count DESC NULLS LAST,
         badge_name
LIMIT 10;