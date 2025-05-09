WITH base_users AS (
    /* users that joined on or before 2021-10-01 */
    SELECT
        u."id"                                   AS "user_id",
        u."reputation",
        TO_TIMESTAMP(u."creation_date" / 1000000)   AS "created_at"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    WHERE u."creation_date" <= 1633046400 * 1000000      -- 2021-10-01 00:00:00 UTC in µs
),
users_with_years AS (
    /* completed full membership years as of 2021-10-01 */
    SELECT
        bu."user_id",
        bu."reputation",
        DATEDIFF(
            year,
            TO_DATE(bu."created_at"),
            TO_DATE('2021-10-01')
        )                                            AS "completed_years"
    FROM base_users bu
),
badge_totals AS (
    /* total badges per user (0 if none) */
    SELECT
        b."user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    GROUP BY b."user_id"
),
combined AS (
    /* merge reputation, badge total and years */
    SELECT
        uy."completed_years",
        uy."reputation",
        COALESCE(bt."badge_count", 0) AS "badge_count"
    FROM users_with_years uy
    LEFT JOIN badge_totals bt
           ON uy."user_id" = bt."user_id"
)
SELECT
    "completed_years",
    AVG("reputation")   AS "avg_reputation",
    AVG("badge_count")  AS "avg_badges",
    COUNT(*)            AS "user_count"
FROM combined
GROUP BY "completed_years"
ORDER BY "completed_years";