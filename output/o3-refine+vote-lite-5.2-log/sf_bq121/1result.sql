WITH users_pre AS (   -- users who joined on or before 2021‑10‑01
    SELECT
        "id"                                   AS USER_ID,
        "reputation"                           AS REPUTATION,
        TO_TIMESTAMP_LTZ("creation_date" / 1000000) AS CREATION_TS
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE "creation_date" IS NOT NULL
      AND TO_TIMESTAMP_LTZ("creation_date" / 1000000)::DATE <= '2021-10-01'
),
user_badges AS (      -- badges earned up to 2021‑10‑01
    SELECT
        "user_id"                             AS USER_ID,
        COUNT(*)                              AS BADGE_CNT
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    WHERE TO_TIMESTAMP_LTZ("date" / 1000000)::DATE <= '2021-10-01'
    GROUP BY "user_id"
),
user_stats AS (       -- combine users and badges, compute completed membership years
    SELECT
        u.USER_ID,
        u.REPUTATION,
        COALESCE(b.BADGE_CNT, 0)                              AS BADGE_CNT,
        DATEDIFF('year', u.CREATION_TS::DATE, '2021-10-01')   AS FULL_YEARS
    FROM users_pre u
    LEFT JOIN user_badges b
           ON u.USER_ID = b.USER_ID
)
SELECT
    FULL_YEARS                                    AS MEMBERSHIP_YEARS,
    ROUND(AVG(REPUTATION), 4)                     AS AVG_REPUTATION,
    ROUND(AVG(BADGE_CNT), 4)                      AS AVG_BADGES_PER_USER
FROM user_stats
GROUP BY FULL_YEARS
ORDER BY FULL_YEARS;