/* Difference between the counts of oldest-age and youngest-age users
   registered from 01-Jan-2019 through 30-Apr-2022                         */

WITH filtered_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000    -- 01-Jan-2019 00:00:00
                          AND 1651363199999999    -- 30-Apr-2022 23:59:59
),
age_limits AS (
    SELECT MIN("age") AS youngest_age,
           MAX("age") AS oldest_age
    FROM filtered_users
),
age_counts AS (
    SELECT
        COUNT_IF("age" = (SELECT youngest_age FROM age_limits)) AS youngest_age_user_count,
        COUNT_IF("age" = (SELECT oldest_age   FROM age_limits)) AS oldest_age_user_count
    FROM filtered_users
)
SELECT
    ABS(oldest_age_user_count - youngest_age_user_count)
        AS "difference_between_oldest_and_youngest_user_counts"
FROM age_counts;