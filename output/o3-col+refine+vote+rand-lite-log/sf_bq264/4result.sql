-- Difference between the number of oldest-age and youngest-age users 
-- registered from 01-Jan-2019 to 30-Apr-2022
WITH period_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000   -- 2019-01-01
                          AND 1651363200000000   -- 2022-04-30
),
age_counts AS (
    SELECT "age",
           COUNT(*) AS "cnt"
    FROM period_users
    GROUP BY "age"
),
youngest_oldest AS (
    SELECT 
        MAX(CASE WHEN "age" = (SELECT MIN("age") FROM age_counts) THEN "cnt" END) AS "youngest_cnt",
        MAX(CASE WHEN "age" = (SELECT MAX("age") FROM age_counts) THEN "cnt" END) AS "oldest_cnt"
    FROM age_counts
)
SELECT 
       "oldest_cnt" - "youngest_cnt" AS "difference_oldest_vs_youngest"
FROM youngest_oldest;