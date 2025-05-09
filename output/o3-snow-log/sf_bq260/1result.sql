/*  How many users are at the youngest age and how many are at the oldest age  
    for each gender between 2019-01-01 and 2022-04-30 (inclusive)               */
WITH youngest AS (   -- youngest age per gender in the period
    SELECT
        "gender",
        MIN("age") AS "youngest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
),
oldest AS (          -- oldest age per gender in the period
    SELECT
        "gender",
        MAX("age") AS "oldest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
),
youngest_cnt AS (    -- count users at the youngest age
    SELECT
        u."gender",
        COUNT(*) AS "youngest_user_count"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN youngest y
      ON u."gender" = y."gender"
     AND u."age"    = y."youngest_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
),
oldest_cnt AS (      -- count users at the oldest age
    SELECT
        u."gender",
        COUNT(*) AS "oldest_user_count"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN oldest o
      ON u."gender" = o."gender"
     AND u."age"    = o."oldest_age"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY u."gender"
)
SELECT
    COALESCE(y."gender", o."gender") AS "gender",
    y."youngest_user_count",
    o."oldest_user_count"
FROM youngest_cnt y
FULL OUTER JOIN oldest_cnt o
  ON y."gender" = o."gender"
ORDER BY "gender";