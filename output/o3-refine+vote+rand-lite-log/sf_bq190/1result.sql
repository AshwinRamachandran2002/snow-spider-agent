WITH filtered_users AS (
    SELECT 
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
      AND "gender" IN ('M','F')
),
age_limits AS (
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
),
youngest AS (
    SELECT
        f."gender",
        'youngest' AS age_group,
        a.min_age AS age,
        COUNT(*) AS user_count
    FROM age_limits a
    JOIN filtered_users f
      ON f."gender" = a."gender"
     AND f."age" = a.min_age
    GROUP BY f."gender", a.min_age
),
oldest AS (
    SELECT
        f."gender",
        'oldest'  AS age_group,
        a.max_age AS age,
        COUNT(*)  AS user_count
    FROM age_limits a
    JOIN filtered_users f
      ON f."gender" = a."gender"
     AND f."age" = a.max_age
    GROUP BY f."gender", a.max_age
)
SELECT * 
FROM youngest
UNION ALL
SELECT * 
FROM oldest
ORDER BY "gender", age_group;