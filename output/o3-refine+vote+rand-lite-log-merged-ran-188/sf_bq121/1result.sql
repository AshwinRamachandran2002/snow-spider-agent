WITH per_user AS (
    SELECT 
        u."id"                                                 AS "user_id",
        /* complete membership years up to 2021-10-01 */
        FLOOR((1633046400000000 - u."creation_date") 
              / 31536000000000)                                AS "membership_years",
        u."reputation"                                         AS "reputation",
        COUNT(b."id")                                          AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS   u
    LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.BADGES b
           ON u."id" = b."user_id"
    /* consider only users who joined on or before 2021-10-01 */
    WHERE u."creation_date" <= 1633046400000000
    GROUP BY u."id", u."creation_date", u."reputation"
)

SELECT
    "membership_years",
    ROUND(AVG("reputation"), 4)  AS "avg_reputation",
    ROUND(AVG("badge_cnt"), 4)   AS "avg_badges"
FROM per_user
GROUP BY "membership_years"
ORDER BY "membership_years";