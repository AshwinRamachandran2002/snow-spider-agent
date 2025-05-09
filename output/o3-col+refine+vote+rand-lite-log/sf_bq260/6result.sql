-- Number of youngest and oldest users per gender between 2019-01-01 and 2022-04-30
WITH extremes AS (
    SELECT
        "gender",
        MIN("age") AS "youngest_age",
        MAX("age") AS "oldest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
    GROUP BY "gender"
)
SELECT
    u."gender",
    CASE
        WHEN u."age" = e."youngest_age" THEN 'youngest'
        WHEN u."age" = e."oldest_age"   THEN 'oldest'
    END AS "age_group",
    COUNT(*) AS "num_users"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
JOIN extremes e
  ON u."gender" = e."gender"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
  AND (u."age" = e."youngest_age" OR u."age" = e."oldest_age")
GROUP BY
    u."gender",
    CASE
        WHEN u."age" = e."youngest_age" THEN 'youngest'
        WHEN u."age" = e."oldest_age"   THEN 'oldest'
    END
ORDER BY
    u."gender",
    "age_group";