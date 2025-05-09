/*  Average reputation and average badge count
    per cohort of complete membership years,
    for users who joined on or before 1‑Oct‑2021                       */

WITH users_enriched AS (          -- join date & reputation of eligible users
    SELECT
        u."id"                                               AS "user_id",
        u."reputation"                                       AS "reputation",
        TO_DATE(TO_TIMESTAMP_LTZ(u."creation_date"/1000000)) AS "join_date"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    WHERE TO_DATE(TO_TIMESTAMP_LTZ(u."creation_date"/1000000)) <= '2021-10-01'
),

badges_per_user AS (              -- how many badges each user has
    SELECT
        "user_id",
        COUNT(*) AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),

users_with_badges AS (            -- combine user info with badge counts
    SELECT
        ue."user_id",
        ue."reputation",
        ue."join_date",
        COALESCE(b."badge_cnt", 0) AS "badge_cnt"
    FROM users_enriched     ue
    LEFT JOIN badges_per_user b
           ON ue."user_id" = b."user_id"
)

SELECT
    DATEDIFF(year, "join_date", '2021-10-01') AS "full_years",
    COUNT(*)                                  AS "user_cnt",
    AVG("reputation")                         AS "avg_reputation",
    AVG("badge_cnt")                          AS "avg_badges"
FROM users_with_badges
GROUP BY "full_years"
ORDER BY "full_years";