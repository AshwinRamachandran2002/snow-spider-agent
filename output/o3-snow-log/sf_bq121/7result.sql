WITH per_user AS (
    SELECT
        u."id"                                                   AS "user_id",
        DATEDIFF(
            year,
            TO_TIMESTAMP(u."creation_date" / 1000000),
            '2021-10-01'
        )                                                        AS "membership_years",
        u."reputation"                                           AS "reputation",
        COUNT(b."id")                                            AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS   AS u
    LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.BADGES  AS b
           ON u."id" = b."user_id"
    -- keep only users who joined on or before 2021-10-01
    WHERE TO_TIMESTAMP(u."creation_date" / 1000000) <= '2021-10-01'
    GROUP BY
        u."id",
        "membership_years",
        u."reputation"
)

SELECT
    "membership_years",
    AVG("reputation") AS "avg_reputation",
    AVG("badge_cnt")  AS "avg_badges"
FROM per_user
GROUP BY "membership_years"
ORDER BY "membership_years" ASC;