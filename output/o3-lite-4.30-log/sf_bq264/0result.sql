WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000   -- 2019‑01‑01 to 2022‑04‑30
), extremes AS (
    SELECT MAX("age") AS max_age,
           MIN("age") AS min_age
    FROM filtered_users
)
SELECT
      (SELECT COUNT(*) FROM filtered_users f, extremes e WHERE f."age" = e.max_age)
    - (SELECT COUNT(*) FROM filtered_users f, extremes e WHERE f."age" = e.min_age)
    AS "users_difference";