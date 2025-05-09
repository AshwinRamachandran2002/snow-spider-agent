WITH first_gold AS (
    -- first gold-badge date for every user
    SELECT
        "user_id",
        MIN("date") AS "first_gold_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1                            -- gold badges
    GROUP BY "user_id"
),
gold_details AS (
    -- badge name and days from account creation to that first gold badge
    SELECT
        b."name"                                                   AS "badge_name",
        (b."date" - u."creation_date") / 86400000000.0             AS "days_to_badge"
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.BADGES  b
         ON b."user_id" = fg."user_id"
        AND b."date"    = fg."first_gold_date"
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS   u
         ON u."id"      = b."user_id"
)
SELECT
    "badge_name",
    COUNT(*)               AS "users_first_gold",
    AVG("days_to_badge")   AS "avg_days_to_badge"
FROM gold_details
GROUP BY "badge_name"
ORDER BY "users_first_gold" DESC NULLS LAST
LIMIT 10;