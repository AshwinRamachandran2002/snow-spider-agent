/* youngest vs oldest user counts per gender, users created between 2019‑01‑01 and 2022‑04‑30 */
WITH filtered_users AS (
    SELECT  "id",
            "gender",
            "age"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE   TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) BETWEEN '2019-01-01' AND '2022-04-30'
      AND   "gender" IS NOT NULL
      AND   "age"    IS NOT NULL
),
age_extremes AS (
    SELECT  "gender",
            MIN("age") AS youngest_age,
            MAX("age") AS oldest_age
    FROM    filtered_users
    GROUP BY "gender"
),
flagged AS (
    SELECT  f."gender"  AS gender,
            f."age"     AS age,
            CASE
                WHEN f."age" = a.youngest_age THEN 'youngest'
                WHEN f."age" = a.oldest_age   THEN 'oldest'
            END         AS age_group
    FROM    filtered_users f
    JOIN    age_extremes  a
      ON    f."gender" = a."gender"
     AND    (f."age" = a.youngest_age OR f."age" = a.oldest_age)
)
SELECT  gender,
        age_group,
        age,
        COUNT(*) AS user_count
FROM    flagged
GROUP BY gender, age_group, age
ORDER BY gender, age_group;