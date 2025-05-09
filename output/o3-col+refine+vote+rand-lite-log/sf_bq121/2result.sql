WITH badge_totals AS (
    SELECT 
        "user_id",
        COUNT(*) AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
users_enriched AS (
    SELECT
        u."id"                                                           AS "user_id",
        FLOOR( (1633046400000000 - u."creation_date")/1000000/60/60/24/365 ) 
                                                                        AS "membership_years",
        u."reputation",
        COALESCE(b."badge_cnt", 0)                                       AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN badge_totals b
           ON u."id" = b."user_id"
    WHERE u."creation_date" <= 1633046400000000   -- joined on or before 1-Oct-2021
)
SELECT
    "membership_years",
    AVG("reputation") AS "avg_reputation",
    AVG("badge_cnt")  AS "avg_badges",
    COUNT(*)          AS "user_cnt"
FROM users_enriched
GROUP BY "membership_years"
ORDER BY "membership_years";