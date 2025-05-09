WITH badges_per_user AS (
    SELECT
        "user_id",
        COUNT(*) AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
users_base AS (
    SELECT
        u."id"                                                       AS user_id,
        TO_TIMESTAMP(u."creation_date" / 1000000)::DATE              AS join_date,
        DATEDIFF(
            'year',
            TO_TIMESTAMP(u."creation_date" / 1000000)::DATE,
            '2021-10-01'
        )                                                            AS member_years,
        u."reputation"                                               AS reputation
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS u
    WHERE TO_TIMESTAMP(u."creation_date" / 1000000)::DATE <= '2021-10-01'
)
SELECT
    ub.member_years,
    AVG(ub.reputation)                       AS avg_reputation,
    AVG(COALESCE(bp.badge_cnt, 0))           AS avg_badges,
    COUNT(*)                                 AS user_cnt
FROM users_base         ub
LEFT JOIN badges_per_user bp
       ON ub.user_id = bp."user_id"
GROUP BY ub.member_years
ORDER BY ub.member_years;