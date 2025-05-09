WITH gold_badges AS (
    SELECT
        "user_id",
        "name",
        "date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1                        -- gold badges only
),
first_gold AS (
    SELECT DISTINCT
        "user_id",
        FIRST_VALUE("name") OVER (PARTITION BY "user_id"
                                  ORDER BY "date", "name")  AS "badge_name",
        MIN("date")         OVER (PARTITION BY "user_id")   AS "badge_date"
    FROM gold_badges
),
first_gold_with_lag AS (
    SELECT
        fg."badge_name",
        fg."user_id",
        (fg."badge_date" - u."creation_date") / 86400000000.0  AS "days_to_badge"
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON fg."user_id" = u."id"
)
SELECT
    "badge_name",
    COUNT(*)                        AS "num_users",
    ROUND(AVG("days_to_badge"), 4)  AS "avg_days_to_badge"
FROM first_gold_with_lag
GROUP BY "badge_name"
ORDER BY "num_users" DESC NULLS LAST
LIMIT 10;