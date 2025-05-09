WITH users_pre_20211001 AS (
    SELECT
        "id"                                      AS user_id,
        TO_TIMESTAMP("creation_date" / 1000000)   AS joined_at,
        "reputation"                              AS reputation
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP("creation_date" / 1000000) <= '2021-10-01'
),
badge_counts AS (
    SELECT
        "user_id",
        COUNT(*) AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
)
SELECT
    years_member,
    ROUND(AVG(reputation), 4) AS avg_reputation,
    ROUND(AVG(badge_cnt), 4)  AS avg_badges
FROM (
    SELECT
        u.user_id,
        DATEDIFF('year', u.joined_at, '2021-10-01') AS years_member,
        u.reputation,
        COALESCE(b.badge_cnt, 0)                    AS badge_cnt
    FROM users_pre_20211001 u
    LEFT JOIN badge_counts b
           ON u.user_id = b."user_id"
)
GROUP BY years_member
ORDER BY years_member;