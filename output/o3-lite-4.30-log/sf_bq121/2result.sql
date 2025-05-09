WITH "badge_counts" AS (
    SELECT "user_id",
           COUNT(*) AS "badge_cnt"
    FROM   STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP  BY "user_id"
),
"users_with_years" AS (
    SELECT  u."id" AS "user_id",
            FLOOR( (1633046400000000 - u."creation_date")
                   / 1000000 / 60 / 60 / 24 / 365 ) AS "years_member",
            u."reputation",
            COALESCE(b."badge_cnt", 0) AS "badge_cnt"
    FROM   STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT   JOIN "badge_counts" b
           ON u."id" = b."user_id"
    WHERE  u."creation_date" <= 1633046400000000  -- joined on or before 2021‑10‑01
)
SELECT "years_member",
       ROUND(AVG("reputation"), 4) AS "avg_reputation",
       ROUND(AVG("badge_cnt"), 4)  AS "avg_badges"
FROM   "users_with_years"
GROUP  BY "years_member"
ORDER  BY "years_member";