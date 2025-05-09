/* Youngest & oldest user counts (per gender) for sign-ups between
   01-Jan-2019 and 30-Apr-2022                                         */

WITH filtered_users AS (               -- keep users within the date window
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000      -- 2019-01-01
                         AND     1651276800000000      -- 2022-04-30
      AND "gender" IN ('M','F')                       -- only M & F
),

age_counts AS (                        -- count users per gender & age
    SELECT
        "gender",
        "age",
        COUNT(*) AS "user_count"
    FROM filtered_users
    GROUP BY "gender", "age"
),

min_max_age AS (                       -- find min & max ages per gender
    SELECT
        "gender",
        MIN("age") AS "min_age",
        MAX("age") AS "max_age"
    FROM filtered_users
    GROUP BY "gender"
)

SELECT
    ac."gender",
    CASE 
        WHEN ac."age" = mm."min_age" THEN 'youngest'
        WHEN ac."age" = mm."max_age" THEN 'oldest'
    END              AS "age_type",
    ac."age"         AS "age_value",
    ac."user_count"
FROM age_counts ac
JOIN min_max_age mm
  ON ac."gender" = mm."gender"
 AND (ac."age" = mm."min_age" OR ac."age" = mm."max_age")
ORDER BY ac."gender", "age_type";