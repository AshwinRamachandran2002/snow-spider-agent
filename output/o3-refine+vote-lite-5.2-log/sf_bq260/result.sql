/*  Youngest vs. oldest user counts per gender
    among users created between 01‑Jan‑2019 and 30‑Apr‑2022  */

WITH user_period AS (          -- users within the requested time window
    SELECT
        "gender",
        "age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE
        TO_TIMESTAMP_NTZ("created_at" / 1000000)::DATE BETWEEN '2019-01-01' AND '2022-04-30'
        AND "gender" IS NOT NULL
        AND "age"    IS NOT NULL
),

age_extremes AS (              -- youngest & oldest age for each gender
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM user_period
    GROUP BY "gender"
),

edge_users AS (                -- keep only those users whose age is an extreme
    SELECT
        u."gender",
        CASE
            WHEN u."age" = a.youngest_age THEN 'youngest'
            WHEN u."age" = a.oldest_age   THEN 'oldest'
        END AS age_group
    FROM user_period u
    JOIN age_extremes a
      ON u."gender" = a."gender"
     AND (u."age" = a.youngest_age OR u."age" = a.oldest_age)
)

SELECT
    "gender",
    SUM(CASE WHEN age_group = 'youngest' THEN 1 ELSE 0 END) AS youngest_user_count,
    SUM(CASE WHEN age_group = 'oldest'   THEN 1 ELSE 0 END) AS oldest_user_count
FROM edge_users
GROUP BY "gender"
ORDER BY "gender";