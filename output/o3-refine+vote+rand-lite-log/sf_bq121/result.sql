WITH "BADGE_COUNTS" AS (
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
"USER_DATA" AS (
    SELECT
        u."id"                             AS "user_id",
        u."reputation"                     AS "reputation",
        COALESCE(b."badge_count", 0)       AS "badge_count",
        DATEDIFF(
            year,
            DATE_TRUNC('day', TO_TIMESTAMP(u."creation_date" / 1000000)),
            DATE '2021-10-01'
        )                                  AS "membership_years"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN "BADGE_COUNTS" b
           ON u."id" = b."user_id"
    WHERE DATE_TRUNC('day', TO_TIMESTAMP(u."creation_date" / 1000000))
          <= DATE '2021-10-01'
)
SELECT
    "membership_years",
    AVG("reputation")   AS "avg_reputation",
    AVG("badge_count")  AS "avg_badges"
FROM "USER_DATA"
GROUP BY "membership_years"
ORDER BY "membership_years";