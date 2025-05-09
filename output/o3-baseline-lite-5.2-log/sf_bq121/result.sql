WITH "BADGE_COUNTS" AS (   -- number of badges each user has earned
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),

"USER_STATS" AS (          -- per‑user data with completed‑year tenure
    SELECT
        u."id"                                                  AS "user_id",
        FLOOR(
            DATEDIFF(
                'month',
                TO_TIMESTAMP_NTZ(u."creation_date" / 1000000),  -- user join date
                TO_DATE('2021-10-01')                           -- cut‑off date
            ) / 12                                              -- complete years
        )                                                      AS "membership_years",
        u."reputation",
        COALESCE(b."badge_count", 0)                           AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN "BADGE_COUNTS" b
           ON u."id" = b."user_id"
    WHERE TO_TIMESTAMP_NTZ(u."creation_date" / 1000000) <= TO_DATE('2021-10-01')
)

SELECT
    "membership_years",
    AVG("reputation")  AS "avg_reputation",
    AVG("badge_count") AS "avg_badges"
FROM "USER_STATS"
GROUP BY "membership_years"
ORDER BY "membership_years";