WITH ref_date AS (                       -- constant cut‑off date
    SELECT TO_DATE('2021-10-01') AS ref_date
),

/* Users who joined on or before the cut‑off date */
eligible_users AS (
    SELECT
        u."id"                                          AS user_id,
        u."reputation"                                  AS reputation,
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)
        )::DATE                                         AS join_date,
        DATEDIFF(
            'year',
            DATE_TRUNC('day', TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)),
            (SELECT ref_date FROM ref_date)
        )                                               AS years_member
    FROM STACKOVERFLOW.STACKOVERFLOW."USERS" u,
         ref_date
    WHERE DATE_TRUNC('day', TO_TIMESTAMP_LTZ(u."creation_date" / 1000000))
          <= (SELECT ref_date FROM ref_date)
),

/* Total badges per user */
badge_totals AS (
    SELECT
        b."user_id",
        COUNT(*) AS badge_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    GROUP BY b."user_id"
)

/* Average reputation and badge count by completed membership years */
SELECT
    eu.years_member                                   AS years_of_membership,
    AVG(eu.reputation)            ::NUMBER(38,4)      AS avg_reputation,
    AVG(COALESCE(bt.badge_cnt, 0))::NUMBER(38,4)      AS avg_badges
FROM eligible_users eu
LEFT JOIN badge_totals bt
       ON eu.user_id = bt."user_id"
GROUP BY eu.years_member
ORDER BY eu.years_member;