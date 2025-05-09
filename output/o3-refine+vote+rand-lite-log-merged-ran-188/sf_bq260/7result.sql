-- Description: For users created between 2019-01-01 (inclusive) and 2022-05-01 (exclusive),
--              return, for each gender, how many users are at the youngest age and
--              how many are at the oldest age within that period.
SELECT
    y."gender",
    y."youngest_age",
    y."num_users_at_youngest_age",
    o."oldest_age",
    o."num_users_at_oldest_age"
FROM (
    /* Youngest-age counts per gender */
    SELECT
        u."gender",
        u."age" AS "youngest_age",
        COUNT(*) AS "num_users_at_youngest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    /* Youngest age for each gender in the period */
    JOIN (
        SELECT
            "gender",
            MIN("age") AS "youngest_age"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
        WHERE "created_at" >= 1546300800000000      -- 2019-01-01
          AND "created_at" <  1651363200000000      -- 2022-05-01 (exclusive)
        GROUP BY "gender"
    ) m
      ON u."gender" = m."gender"
     AND u."age"    = m."youngest_age"
    WHERE u."created_at" >= 1546300800000000
      AND u."created_at" <  1651363200000000
    GROUP BY u."gender", u."age"
) y
JOIN (
    /* Oldest-age counts per gender */
    SELECT
        u."gender",
        u."age" AS "oldest_age",
        COUNT(*) AS "num_users_at_oldest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    /* Oldest age for each gender in the period */
    JOIN (
        SELECT
            "gender",
            MAX("age") AS "oldest_age"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
        WHERE "created_at" >= 1546300800000000      -- 2019-01-01
          AND "created_at" <  1651363200000000      -- 2022-05-01 (exclusive)
        GROUP BY "gender"
    ) x
      ON u."gender" = x."gender"
     AND u."age"    = x."oldest_age"
    WHERE u."created_at" >= 1546300800000000
      AND u."created_at" <  1651363200000000
    GROUP BY u."gender", u."age"
) o
  ON y."gender" = o."gender"
ORDER BY y."gender";