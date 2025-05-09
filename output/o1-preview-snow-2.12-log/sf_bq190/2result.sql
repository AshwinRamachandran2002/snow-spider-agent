WITH filtered_users AS (
    SELECT "gender", "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199999999
)
SELECT
    s."gender" AS "Gender",
    s."min_age" AS "Min_Age",
    COUNT(CASE WHEN u."age" = s."min_age" THEN 1 END) AS "Users_with_Min_Age",
    s."max_age" AS "Max_Age",
    COUNT(CASE WHEN u."age" = s."max_age" THEN 1 END) AS "Users_with_Max_Age"
FROM (
    SELECT "gender", MIN("age") AS "min_age", MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
) s
JOIN filtered_users u
    ON u."gender" = s."gender"
GROUP BY s."gender", s."min_age", s."max_age"
ORDER BY s."gender";