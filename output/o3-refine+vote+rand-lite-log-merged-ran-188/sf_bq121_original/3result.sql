WITH users_filtered AS (
    SELECT
        "id"                                            AS user_id,
        "reputation"                                    AS reputation,
        TO_TIMESTAMP_NTZ("creation_date" / 1000000)     AS creation_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE TO_TIMESTAMP_NTZ("creation_date" / 1000000)::DATE <= '2021-10-01'
),
badges_per_user AS (
    SELECT
        "user_id"                                       AS user_id,
        COUNT(*)                                        AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
user_stats AS (
    SELECT
        uf.user_id,
        DATEDIFF('year', uf.creation_ts::DATE, '2021-10-01') AS years_member,
        uf.reputation,
        COALESCE(bp.badge_cnt, 0)                        AS badge_cnt
    FROM users_filtered uf
    LEFT JOIN badges_per_user bp
        ON uf.user_id = bp.user_id
)
SELECT
    years_member,
    ROUND(AVG(reputation), 4)  AS avg_reputation,
    ROUND(AVG(badge_cnt), 4)   AS avg_badges
FROM user_stats
GROUP BY years_member
ORDER BY years_member ASC NULLS LAST;