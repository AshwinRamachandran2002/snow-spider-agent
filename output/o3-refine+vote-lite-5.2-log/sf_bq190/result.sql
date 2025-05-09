WITH filtered_users AS (   -- users who signed up between 2019‑01‑01 and 2022‑04‑30
    SELECT
        "id",
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) BETWEEN '2019-01-01' AND '2022-04-30'
          AND "gender" IN ('M','F')         -- keep only male / female
), gender_extremes AS (     -- youngest & oldest age per gender
    SELECT
        "gender",
        MIN("age") AS min_age,
        MAX("age") AS max_age
    FROM filtered_users
    GROUP BY "gender"
)
SELECT
    g."gender",
    g.min_age                          AS youngest_age,
    COUNT(CASE WHEN f."age" = g.min_age THEN 1 END) AS num_youngest_users,
    g.max_age                          AS oldest_age,
    COUNT(CASE WHEN f."age" = g.max_age THEN 1 END) AS num_oldest_users
FROM gender_extremes g
JOIN filtered_users f
      ON f."gender" = g."gender"
GROUP BY
    g."gender",
    g.min_age,
    g.max_age
ORDER BY
    g."gender";