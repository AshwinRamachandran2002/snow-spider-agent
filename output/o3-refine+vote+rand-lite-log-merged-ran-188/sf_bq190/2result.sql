WITH filtered_users AS (
    /* users who signed‑up between 2019‑01‑01 and 2022‑04‑30 (inclusive) */
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE
        TO_TIMESTAMP_NTZ("created_at" / 1000000) BETWEEN '2019-01-01' AND '2022-04-30'
),
min_max_age AS (
    /* minimum and maximum age for every gender in that period */
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
),
youngest_oldest_users AS (
    /* keep only users whose age equals the min or max for their gender */
    SELECT
        f."gender",
        CASE 
            WHEN f."age" = m.min_age THEN 'Youngest'   /* minimum age */
            ELSE 'Oldest'                              /* maximum age */
        END                           AS age_type,
        f."age"
    FROM filtered_users f
    JOIN min_max_age   m
          ON f."gender" = m."gender"
         AND (f."age" = m.min_age OR f."age" = m.max_age)
)
SELECT
    "gender",
    age_type,
    "age"           AS age_value,
    COUNT(*)        AS user_count
FROM youngest_oldest_users
GROUP BY
    "gender",
    age_type,
    "age"
ORDER BY
    "gender",
    age_type;