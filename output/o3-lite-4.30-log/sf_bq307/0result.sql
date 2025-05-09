WITH first_gold AS (
    /* earliest gold badge per user */
    SELECT
        b."user_id",
        b."name" AS "badge_name",
        b."date" AS "badge_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    JOIN (
        SELECT
            "user_id",
            MIN("date") AS "first_gold_date"
        FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
        WHERE "class" = 1
          AND "user_id" IS NOT NULL
        GROUP BY "user_id"
    ) fg
      ON b."user_id" = fg."user_id"
     AND b."date"    = fg."first_gold_date"
)
SELECT
    fg."badge_name"                                          AS badge_name,
    COUNT(*)                                                 AS users_first_gold,
    ROUND(
        AVG( (fg."badge_date" - u."creation_date") / 86400000000 ),
        4
    )                                                        AS avg_days_to_badge
FROM first_gold fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON fg."user_id" = u."id"
GROUP BY fg."badge_name"
ORDER BY users_first_gold DESC NULLS LAST, fg."badge_name"
LIMIT 10;