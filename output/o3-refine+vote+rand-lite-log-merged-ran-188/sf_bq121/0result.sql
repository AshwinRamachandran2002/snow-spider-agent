/*  Average reputation and badge count per completed-year bucket
    for users that joined on or before 2021-10-01                */

WITH user_stats AS (
    SELECT
        u."id"                                                   AS "user_id",
        DATEDIFF(
            'year',
            TO_DATE( TO_TIMESTAMP_LTZ(u."creation_date" / 1000000) ),
            '2021-10-01'                                         -- comparison date
        )                                                        AS "completed_years",
        u."reputation"                                           AS "reputation",
        COUNT(b."id")                                            AS "badge_cnt"   -- 0 when no badges
    FROM   "STACKOVERFLOW"."STACKOVERFLOW"."USERS"  u
    LEFT  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."BADGES" b
           ON b."user_id" = u."id"
    -- include only members who signed up on or before 2021-10-01
    WHERE  u."creation_date" <= 1633046400 * 1000000             -- date in µs
    GROUP BY
        u."id",
        "completed_years",
        u."reputation"
)

SELECT
    "completed_years",
    AVG("reputation")  AS "avg_reputation",
    AVG("badge_cnt")   AS "avg_badges"
FROM   user_stats
GROUP BY "completed_years"
ORDER BY "completed_years";