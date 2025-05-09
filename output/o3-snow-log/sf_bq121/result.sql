WITH badge_counts AS (
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
user_stats AS (
    SELECT
        u."id" AS "user_id",
        DATEDIFF(
            year,
            DATE_TRUNC(year, TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)),
            '2021-10-01'
        ) AS "membership_years",
        u."reputation",
        COALESCE(b."badge_count", 0) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN badge_counts b
           ON u."id" = b."user_id"
    WHERE TO_TIMESTAMP_LTZ(u."creation_date" / 1000000) <= '2021-10-01'
)
SELECT
    "membership_years",
    COUNT(*)                   AS "user_count",
    AVG("reputation")          AS "avg_reputation",
    AVG("badge_count")         AS "avg_badges"
FROM user_stats
GROUP BY "membership_years"
ORDER BY "membership_years";