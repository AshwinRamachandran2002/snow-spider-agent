/*  Youngest & oldest users (per gender) who signed-up between
    01-Jan-2019 and 30-Apr-2022                                    */

WITH age_limits AS (       -- 1) youngest & oldest age per gender
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_TIMESTAMP_NTZ("created_at" / 1000000)
              BETWEEN '2019-01-01' AND '2022-04-30 23:59:59'
    GROUP BY "gender"
),

users_of_interest AS (     -- 2) keep only youngest / oldest users
    SELECT
        u."gender",
        u."age",
        a."min_age",
        a."max_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN age_limits a
      ON u."gender" = a."gender"
     AND (u."age" = a."min_age" OR u."age" = a."max_age")
    WHERE TO_TIMESTAMP_NTZ(u."created_at" / 1000000)
              BETWEEN '2019-01-01' AND '2022-04-30 23:59:59'
)

SELECT
    "gender",
    MIN(CASE WHEN "age" = "min_age" THEN "age" END)                           AS "youngest_age",
    SUM(CASE WHEN "age" = "min_age" THEN 1 ELSE 0 END)                        AS "youngest_user_cnt",
    MAX(CASE WHEN "age" = "max_age" THEN "age" END)                           AS "oldest_age",
    SUM(CASE WHEN "age" = "max_age" THEN 1 ELSE 0 END)                        AS "oldest_user_cnt"
FROM users_of_interest
GROUP BY "gender"
ORDER BY "gender";