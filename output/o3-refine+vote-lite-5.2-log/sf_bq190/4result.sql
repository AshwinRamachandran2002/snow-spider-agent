WITH filtered_users AS (
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE
        /* convert the micro‑second epoch stored in "created_at" to DATE */
        TO_TIMESTAMP_NTZ("created_at" / 1000000)::DATE 
            BETWEEN '2019-01-01' AND '2022-04-30'
        AND "gender" IN ('F', 'M')           -- keep only M/F as required
),

age_bounds AS (
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
)

SELECT
    f."gender",
    a.min_age         AS youngest_age,
    COUNT_IF(f."age" = a.min_age) AS num_of_youngest_users,
    a.max_age         AS oldest_age,
    COUNT_IF(f."age" = a.max_age) AS num_of_oldest_users
FROM filtered_users f
JOIN age_bounds a
  ON f."gender" = a."gender"
GROUP BY
    f."gender",
    a.min_age,
    a.max_age
ORDER BY
    f."gender";