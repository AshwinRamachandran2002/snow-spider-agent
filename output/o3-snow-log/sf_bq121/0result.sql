WITH per_user AS (
    SELECT
        u."id"                                                     AS "user_id",
        DATEDIFF(
            year,
            TO_DATE(TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)),
            '2021-10-01'::DATE
        )                                                          AS "years_complete",
        u."reputation"                                             AS "reputation",
        COUNT(b."id")                                              AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS   AS u
    LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.BADGES  AS b
           ON b."user_id" = u."id"
    WHERE TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)
          <= '2021-10-01'::TIMESTAMP_LTZ
    GROUP BY
        u."id",
        "years_complete",
        u."reputation"
)

SELECT
    "years_complete",
    AVG("reputation")  AS "avg_reputation",
    AVG("badge_cnt")   AS "avg_badges",
    COUNT(*)           AS "users_in_bucket"
FROM per_user
GROUP BY "years_complete"
ORDER BY "years_complete";