/*  Average reputation & badge count by complete years of membership
    (only users who joined on or before 2021-10-01)                     */

WITH badge_counts AS (
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),

users_with_tenure AS (
    SELECT
        u."id"                       AS "user_id",
        u."reputation",
        COALESCE(b."badge_count",0)  AS "badge_count",
        TO_DATE( TO_TIMESTAMP_NTZ(u."creation_date" / 1000000) ) AS "join_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS AS u
    LEFT JOIN badge_counts AS b
           ON u."id" = b."user_id"
    WHERE TO_DATE( TO_TIMESTAMP_NTZ(u."creation_date" / 1000000) )
          <= '2021-10-01'
)

SELECT
    DATEDIFF(year, "join_date", '2021-10-01') AS "member_years",
    COUNT(*)                                  AS "users",
    AVG("reputation")                         AS "avg_reputation",
    AVG("badge_count")                        AS "avg_badges"
FROM users_with_tenure
GROUP BY "member_years"
ORDER BY "member_years";