WITH filtered_users AS (
    SELECT
        "id",
        "age",
        "gender"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_TIMESTAMP("created_at" / 1000000) 
          BETWEEN '2019-01-01' AND '2022-04-30'
          AND "gender" IN ('M', 'F')           -- keep only male & female
),
age_extremes AS (                            -- youngest & oldest age per gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
)

SELECT
    f."gender",
    e.min_age                                                 AS youngest_age,
    SUM(CASE WHEN f."age" = e.min_age THEN 1 ELSE 0 END)     AS youngest_user_count,
    e.max_age                                                 AS oldest_age,
    SUM(CASE WHEN f."age" = e.max_age THEN 1 ELSE 0 END)     AS oldest_user_count
FROM age_extremes e
JOIN filtered_users f
  ON f."gender" = e."gender"
GROUP BY
    f."gender",
    e.min_age,
    e.max_age
ORDER BY
    f."gender";