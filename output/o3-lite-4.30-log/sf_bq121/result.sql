WITH "BADGES_PER_USER" AS (
    SELECT 
        "user_id",
        COUNT(*) AS "badge_cnt"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
)
SELECT
    FLOOR(
        DATEDIFF(
            year,
            TO_TIMESTAMP_NTZ(U."creation_date" / 1000000),
            TO_DATE('2021-10-01')
        )
    )                                    AS "years_member",
    ROUND(AVG(U."reputation"), 4)        AS "avg_reputation",
    ROUND(AVG(COALESCE(B."badge_cnt",0)),4) AS "avg_badges"
FROM STACKOVERFLOW.STACKOVERFLOW.USERS U
LEFT JOIN "BADGES_PER_USER" B
       ON U."id" = B."user_id"
WHERE TO_TIMESTAMP_NTZ(U."creation_date" / 1000000) <= '2021-10-01'
GROUP BY "years_member"
ORDER BY "years_member";