WITH filtered_users AS (
    -- users created between 2019-01-01 and 2022-04-30
    SELECT *
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" >= 1546300800000000   -- 2019-01-01
      AND "created_at" <= 1651363200000000   -- 2022-04-30
), per_gender_extremes AS (
    -- youngest and oldest age per gender inside the window
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM filtered_users
    GROUP BY "gender"
), youngest_counts AS (
    -- how many users sit at the youngest age (per gender)
    SELECT
        f."gender",
        COUNT(*) AS "youngest_user_cnt"
    FROM filtered_users f
    JOIN per_gender_extremes e
      ON f."gender" = e."gender"
     AND f."age"    = e."youngest_age"
    GROUP BY f."gender"
), oldest_counts AS (
    -- how many users sit at the oldest age (per gender)
    SELECT
        f."gender",
        COUNT(*) AS "oldest_user_cnt"
    FROM filtered_users f
    JOIN per_gender_extremes e
      ON f."gender" = e."gender"
     AND f."age"    = e."oldest_age"
    GROUP BY f."gender"
)
SELECT
    e."gender",
    e."youngest_age",
    y."youngest_user_cnt",
    e."oldest_age",
    o."oldest_user_cnt"
FROM per_gender_extremes e
JOIN youngest_counts y ON e."gender" = y."gender"
JOIN oldest_counts  o ON e."gender" = o."gender"
ORDER BY e."gender";