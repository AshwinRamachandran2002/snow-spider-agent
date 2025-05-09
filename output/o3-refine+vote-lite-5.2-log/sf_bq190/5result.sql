WITH filtered_users AS (
    SELECT 
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "gender" IN ('M','F')
      AND "age" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at"/1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
), 
age_extremes AS (
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
    GROUP BY "gender"
)
SELECT
    ae."gender",
    ae.youngest_age,
    SUM(CASE WHEN fu."age" = ae.youngest_age THEN 1 ELSE 0 END) AS num_youngest_users,
    ae.oldest_age,
    SUM(CASE WHEN fu."age" = ae.oldest_age THEN 1 ELSE 0 END) AS num_oldest_users
FROM age_extremes ae
JOIN filtered_users fu
  ON fu."gender" = ae."gender"
GROUP BY
    ae."gender",
    ae.youngest_age,
    ae.oldest_age
ORDER BY
    ae."gender";