WITH badge_counts AS (
    SELECT 
        "user_id",
        COUNT(*) AS badge_count
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
users_pre_20211001 AS (
    SELECT
        u."id" AS user_id,
        -- completed membership years as of 2021-10-01
        FLOOR( (1633046400000000 - u."creation_date") / 31536000000000 )  AS years_complete,
        u."reputation"  AS reputation,
        COALESCE(bc.badge_count, 0)                                        AS badge_count
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN badge_counts bc
        ON bc."user_id" = u."id"
    WHERE u."creation_date" <= 1633046400000000
)
SELECT
    years_complete,
    AVG(reputation)   AS avg_reputation,
    AVG(badge_count)  AS avg_badges,
    COUNT(*)          AS users_in_bucket
FROM users_pre_20211001
GROUP BY years_complete
ORDER BY years_complete;