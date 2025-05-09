WITH users_filtered AS (   -- keep only users created between 2019‑01‑01 and 2022‑04‑30 (inclusive)
    SELECT 
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "gender" IS NOT NULL
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) >= '2019-01-01'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) <  '2022-05-01'     -- up to 2022‑04‑30 23:59:59
),                                                             
age_extremes AS (           -- youngest & oldest age per gender
    SELECT 
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM users_filtered
    GROUP BY "gender"
),
youngest_cnt AS (           -- count users at the youngest age, per gender
    SELECT 
        uf."gender",
        'Youngest' AS age_group,
        ae.youngest_age AS age,
        COUNT(*) AS user_count
    FROM users_filtered uf
    JOIN age_extremes  ae
      ON uf."gender" = ae."gender"
     AND uf."age"     = ae.youngest_age
    GROUP BY uf."gender", ae.youngest_age
),
oldest_cnt AS (             -- count users at the oldest age, per gender
    SELECT 
        uf."gender",
        'Oldest'  AS age_group,
        ae.oldest_age AS age,
        COUNT(*) AS user_count
    FROM users_filtered uf
    JOIN age_extremes  ae
      ON uf."gender" = ae."gender"
     AND uf."age"     = ae.oldest_age
    GROUP BY uf."gender", ae.oldest_age
)
SELECT 
    "gender",
    age_group,
    age,
    user_count
FROM (
    SELECT * FROM youngest_cnt
    UNION ALL
    SELECT * FROM oldest_cnt
)
ORDER BY "gender", age_group;