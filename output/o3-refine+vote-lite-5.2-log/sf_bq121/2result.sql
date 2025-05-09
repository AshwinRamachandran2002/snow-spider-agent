WITH ref AS (                                   -- reference date: 01‑OCT‑2021
    SELECT TO_DATE('2021-10-01') AS ref_date
),

/* total badges each user has earned */
badge_totals AS (
    SELECT  "user_id",
            COUNT(*) AS badge_cnt
    FROM    STACKOVERFLOW.STACKOVERFLOW."BADGES"
    GROUP BY "user_id"
),

/* users who joined on or before the reference date,
   together with their badge counts */
users_pre_ref AS (
    SELECT  u."id"                               AS user_id,
            u."reputation"                       AS reputation,
            COALESCE(b.badge_cnt,0)              AS badge_cnt,
            TO_DATE(TO_TIMESTAMP_NTZ(u."creation_date"/1000000)) AS join_date,
            r.ref_date                           AS ref_date
    FROM    STACKOVERFLOW.STACKOVERFLOW."USERS" u
    CROSS   JOIN ref r
    LEFT    JOIN badge_totals b
           ON u."id" = b."user_id"
    WHERE   TO_DATE(TO_TIMESTAMP_NTZ(u."creation_date"/1000000)) <= r.ref_date
),

/* compute number of COMPLETE membership years for every user */
tenure AS (
    SELECT  user_id,
            reputation,
            badge_cnt,
            CASE
                WHEN DATEADD('year',
                             DATEDIFF('year', join_date, ref_date),
                             join_date) > ref_date
                THEN DATEDIFF('year', join_date, ref_date) - 1
                ELSE DATEDIFF('year', join_date, ref_date)
            END AS years_of_membership
    FROM    users_pre_ref
)

/* final aggregation */
SELECT  years_of_membership,
        AVG(reputation)  AS average_reputation,
        AVG(badge_cnt)   AS average_badges
FROM    tenure
GROUP BY years_of_membership
ORDER BY years_of_membership;