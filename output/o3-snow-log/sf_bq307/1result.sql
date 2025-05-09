WITH first_gold AS (
    /* All gold-badge events with a rank per user by earliest date */
    SELECT
        "user_id",
        "name"            AS "badge_name",
        "date"            AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE "class" = 1
),
first_gold_only AS (
    /* Keep only the first gold badge each user earned */
    SELECT
        "user_id",
        "badge_name",
        "badge_date"
    FROM first_gold
    WHERE "rn" = 1
),
elapsed_days AS (
    /* Compute days from account creation to first gold badge */
    SELECT
        fg."badge_name",
        (fg."badge_date" - u."creation_date") / 86400000000.0 AS "days_to_first_gold"
    FROM first_gold_only fg
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
          ON fg."user_id" = u."id"
)
SELECT
    "badge_name",
    COUNT(*)                           AS "user_count",
    AVG("days_to_first_gold")          AS "avg_days_to_first_gold"
FROM elapsed_days
GROUP BY "badge_name"
ORDER BY "user_count" DESC NULLS LAST
LIMIT 10;