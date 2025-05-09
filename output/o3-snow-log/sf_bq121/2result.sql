/*  Average reputation and badge counts by complete membership years
    for users who joined on or before 2021-10-01 (micro-seconds epoch
    1633046400000000).                                              */

WITH user_badges AS (
    SELECT
        u."id"                                                   AS "user_id",
        /* complete years of membership at 2021-10-01            */
        FLOOR( (1633046400000000 - u."creation_date")
               / 31536000000000 )                                AS "complete_years",
        u."reputation",
        COUNT(b."id")                                            AS "badge_cnt"
    FROM   STACKOVERFLOW.STACKOVERFLOW."USERS"   u
    LEFT   JOIN STACKOVERFLOW.STACKOVERFLOW."BADGES"  b
           ON u."id" = b."user_id"
    /* consider only users who joined on or before 2021-10-01    */
    WHERE  u."creation_date" <= 1633046400000000
    GROUP  BY u."id",
             u."creation_date",
             u."reputation"
)

SELECT
    "complete_years",
    AVG("reputation")      AS "avg_reputation",
    AVG("badge_cnt")       AS "avg_badges",
    COUNT(*)               AS "users_in_bucket"
FROM   user_badges
GROUP  BY "complete_years"
ORDER  BY "complete_years";