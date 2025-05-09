WITH first_gold AS (
    SELECT
        b."user_id",
        b."name"  AS "badge_name",
        b."date"  AS "badge_date"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."BADGES" b
    WHERE b."class" = 1
    QUALIFY ROW_NUMBER() OVER (
               PARTITION BY b."user_id"
               ORDER BY b."date"
           ) = 1
)
SELECT
    fg."badge_name",
    COUNT(*)                                                     AS "users_first_gold",
    ROUND(AVG( (fg."badge_date" - u."creation_date")
               /(86400*1000000.0) ), 4)                          AS "avg_days_to_badge"
FROM first_gold fg
JOIN "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
  ON u."id" = fg."user_id"
GROUP BY fg."badge_name"
ORDER BY "users_first_gold" DESC NULLS LAST, "badge_name"
LIMIT 10;