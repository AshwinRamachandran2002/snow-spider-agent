/*  Youngest & oldest user counts per gender  
    – sign-ups between 01-Jan-2019 and 30-Apr-2022 (inclusive)              */
WITH users_in_window AS (   -- restrict to required signup period
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN
          DATE_PART(EPOCH_MICROSECOND, TO_TIMESTAMP_NTZ('2019-01-01 00:00:00'))
      AND DATE_PART(EPOCH_MICROSECOND, TO_TIMESTAMP_NTZ('2022-04-30 23:59:59'))
),
extremes AS (               -- get youngest & oldest age for each gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM users_in_window
    GROUP BY "gender"
)
SELECT
    e."gender",
    e.min_age,
    SUM(CASE WHEN u."age" = e.min_age THEN 1 ELSE 0 END) AS num_users_min_age,
    e.max_age,
    SUM(CASE WHEN u."age" = e.max_age THEN 1 ELSE 0 END) AS num_users_max_age
FROM users_in_window            u
JOIN extremes                   e  ON u."gender" = e."gender"
GROUP BY
    e."gender",
    e.min_age,
    e.max_age
ORDER BY
    e."gender";