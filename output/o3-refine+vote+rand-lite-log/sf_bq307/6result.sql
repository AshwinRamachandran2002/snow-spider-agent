WITH gold_badges AS (
    SELECT
        "user_id",
        "name",
        "date",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "date") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1                               -- gold badges
),
first_gold AS (                                     -- each user's first gold badge
    SELECT
        "user_id",
        "name",
        "date"
    FROM gold_badges
    WHERE rn = 1
),
elapsed AS (                                        -- days from sign‑up to first gold badge
    SELECT
        fg."name",
        DATEDIFF(
            'day',
            TO_TIMESTAMP_LTZ(u."creation_date" / 1000000),   -- account creation
            TO_TIMESTAMP_LTZ(fg."date" / 1000000)            -- badge awarded
        ) AS days_to_badge
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON u."id" = fg."user_id"
)
SELECT
    "name"                                             AS "badge_name",
    COUNT(*)                                           AS "first_gold_user_count",
    AVG(days_to_badge)                                 AS "avg_days_to_first_gold"
FROM elapsed
GROUP BY "name"
ORDER BY
    "first_gold_user_count" DESC NULLS LAST,           -- most common first gold badges
    "badge_name"
LIMIT 10;