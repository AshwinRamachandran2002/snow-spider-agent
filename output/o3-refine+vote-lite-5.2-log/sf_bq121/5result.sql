WITH user_stats AS (
    /* users who joined on or before 2021‑10‑01 and their completed membership years */
    SELECT
        "id"                                               AS "user_id",
        "reputation"                                       AS "reputation",
        FLOOR(
            DATEDIFF(
                'day',
                TO_TIMESTAMP_NTZ("creation_date" / 1000000),
                '2021-10-01'        -- comparison cut‑off date
            ) / 365.25             -- convert days → years, keep only full years
        )                           AS "years_member"
    FROM STACKOVERFLOW.STACKOVERFLOW."USERS"
    WHERE TO_TIMESTAMP_NTZ("creation_date" / 1000000) <= '2021-10-01'
),
badge_totals AS (
    /* total badges each user has earned */
    SELECT
        "user_id",
        COUNT(*) AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"
    GROUP BY "user_id"
),
combined AS (
    /* merge reputation, years of membership, and badge count */
    SELECT
        u."years_member",
        u."reputation",
        COALESCE(b."badge_cnt", 0) AS "badge_cnt"
    FROM user_stats u
    LEFT JOIN badge_totals b
           ON u."user_id" = b."user_id"
)
SELECT
    "years_member",
    AVG("reputation")  AS "avg_reputation",
    AVG("badge_cnt")   AS "avg_badges",
    COUNT(*)           AS "num_users"          -- optional: how many users per group
FROM combined
GROUP BY "years_member"
ORDER BY "years_member";