WITH user_base AS (   -- users who joined on or before 2021-10-01
    SELECT
        "id"                                    AS user_id,
        "reputation"            AS reputation,  -- give the column a case-insensitive alias
        DATEDIFF(
            'year',
            TO_TIMESTAMP("creation_date" / 1000000),
            '2021-10-01'
        )                                       AS tenure_years
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP("creation_date" / 1000000) <= '2021-10-01'
),
badge_totals AS (     -- total badge count per user
    SELECT
        "user_id",
        COUNT(*) AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
users_with_badges AS (  -- combine users with their badge counts (0 if none)
    SELECT
        u.tenure_years,
        u.reputation,
        COALESCE(b.badge_cnt, 0) AS badge_cnt
    FROM user_base u
    LEFT JOIN badge_totals b
      ON u.user_id = b."user_id"
)
SELECT
    tenure_years,
    ROUND(AVG(reputation), 4) AS avg_reputation,
    ROUND(AVG(badge_cnt), 4)  AS avg_badges
FROM users_with_badges
GROUP BY tenure_years
ORDER BY tenure_years;