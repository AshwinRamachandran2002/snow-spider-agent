WITH first_gold AS (
    /* pick each user’s earliest gold-badge award */
    SELECT
        b."user_id",
        b."name"  AS "badge_name",
        b."date"  AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") AS rn
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE b."class" = 1                      -- gold badges only
), first_gold_only AS (
    SELECT
        "user_id",
        "badge_name",
        "badge_date"
    FROM first_gold
    WHERE rn = 1                             -- keep the first gold badge per user
)
SELECT
    fg."badge_name"                                         AS "BADGE_NAME",
    COUNT(fg."user_id")                                     AS "USER_COUNT",
    AVG( (fg."badge_date" - u."creation_date")
         / (86400 * 1000000.0) )                            AS "AVG_DAYS_FROM_SIGNUP"
FROM first_gold_only fg
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON u."id" = fg."user_id"
GROUP BY fg."badge_name"
ORDER BY "USER_COUNT" DESC NULLS LAST
LIMIT 10;