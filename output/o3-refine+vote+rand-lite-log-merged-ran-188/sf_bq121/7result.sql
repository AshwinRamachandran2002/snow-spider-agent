WITH user_base AS (      -- users who joined on/before 2021-10-01
    SELECT
        "id"                                    AS user_id,
        "reputation"                            AS reputation,
        TO_TIMESTAMP_NTZ("creation_date"/1000000) AS created_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP_NTZ("creation_date"/1000000) <= '2021-10-01'::DATE
),
badge_totals AS (        -- total badges each user owns
    SELECT
        "user_id",
        COUNT(*) AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
users_with_badges AS (   -- combine users with their badge counts
    SELECT
        u.user_id,
        DATEDIFF(year, u.created_ts, '2021-10-01'::DATE) AS member_years,
        u.reputation,
        COALESCE(b.badge_cnt, 0) AS badge_cnt
    FROM user_base u
    LEFT JOIN badge_totals b
           ON u.user_id = b."user_id"
)
SELECT
    member_years,
    ROUND(AVG(reputation), 4) AS avg_reputation,
    ROUND(AVG(badge_cnt), 4)  AS avg_badges,
    COUNT(*)                  AS users_in_group
FROM users_with_badges
GROUP BY member_years
ORDER BY member_years;