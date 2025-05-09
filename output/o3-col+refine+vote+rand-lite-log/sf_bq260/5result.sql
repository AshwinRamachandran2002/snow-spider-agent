/* Users at the youngest and oldest ages (by gender) between 01-Jan-2019 and 30-Apr-2022 */
WITH date_filtered_users AS (
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000    -- 01-Jan-2019 00:00:00 (µs)
                          AND 1651363199000000     -- 30-Apr-2022 23:59:59 (µs)
),
age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM date_filtered_users
    GROUP BY "gender"
)
SELECT
    u."gender",
    SUM(CASE WHEN u."age" = b."youngest_age" THEN 1 ELSE 0 END) AS "youngest_user_count",
    SUM(CASE WHEN u."age" = b."oldest_age"   THEN 1 ELSE 0 END) AS "oldest_user_count"
FROM date_filtered_users u
JOIN age_bounds b
  ON u."gender" = b."gender"
GROUP BY u."gender";