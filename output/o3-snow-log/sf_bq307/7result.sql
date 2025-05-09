WITH first_gold_badge_per_user AS (            -- get each user's very first gold badge
    SELECT
        b."user_id",
        b."name"  AS "badge_name",
        b."date"  AS "badge_date",
        u."creation_date" AS "account_creation_date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id"
                           ORDER BY b."date" ASC, b."id" ASC) AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES  AS b
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS   AS u
      ON b."user_id" = u."id"
    WHERE b."class" = 1                      -- gold badges only
)
SELECT
    "badge_name",
    COUNT(*)                                  AS "users_with_this_badge_first",
    AVG( ( "badge_date" - "account_creation_date" ) / 86400 )
                                              AS "avg_days_to_first_gold"
FROM first_gold_badge_per_user
WHERE rn = 1                                  -- keep only the first gold badge per user
GROUP BY "badge_name"
ORDER BY "users_with_this_badge_first" DESC NULLS LAST
LIMIT 10;