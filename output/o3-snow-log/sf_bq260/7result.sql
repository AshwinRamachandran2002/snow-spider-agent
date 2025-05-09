/*  Youngest‐vs‐Oldest user counts by gender between 01-Jan-2019 and 30-Apr-2022 */
WITH filtered_users AS (
    SELECT *
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000            -- 01-Jan-2019 00:00:00
                          AND 1651363200000000             -- 30-Apr-2022 23:59:59
),
age_limits AS (
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
    GROUP BY "gender"
)
SELECT
    fu."gender",
    SUM(CASE WHEN fu."age" = al.youngest_age THEN 1 ELSE 0 END) AS "youngest_user_cnt",
    SUM(CASE WHEN fu."age" = al.oldest_age  THEN 1 ELSE 0 END) AS "oldest_user_cnt"
FROM filtered_users fu
JOIN age_limits al
  ON fu."gender" = al."gender"
GROUP BY fu."gender";