/* Youngest‑vs‑Oldest user counts (per gender) among users created between
   2019‑01‑01 and 2022‑04‑30 (inclusive) */

WITH filtered_users AS (
    /* keep only users created inside the requested period                */
    SELECT
        "gender",
        "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE
          /* "created_at" is stored in micro‑seconds since epoch          */
          "created_at" >= 1546300800000000        -- 2019‑01‑01 00:00:00
      AND "created_at" <= 1651363199000000        -- 2022‑04‑30 23:59:59
      AND "gender" IS NOT NULL
      AND "age"    IS NOT NULL
),

age_limits AS (
    /* youngest and oldest age per gender                                 */
    SELECT
        "gender",
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM filtered_users
    GROUP BY "gender"
),

youngest AS (
    /* users whose age equals the youngest age for their gender           */
    SELECT
        f."gender",
        'Youngest'        AS age_type,
        f."age"           AS age_value,
        COUNT(*)          AS user_count
    FROM filtered_users f
    JOIN age_limits   a
      ON a."gender" = f."gender"
     AND f."age"     = a.youngest_age
    GROUP BY f."gender", f."age"
),

oldest AS (
    /* users whose age equals the oldest age for their gender             */
    SELECT
        f."gender",
        'Oldest'          AS age_type,
        f."age"           AS age_value,
        COUNT(*)          AS user_count
    FROM filtered_users f
    JOIN age_limits   a
      ON a."gender" = f."gender"
     AND f."age"     = a.oldest_age
    GROUP BY f."gender", f."age"
)

/* final result: one row per gender & age‑type (youngest / oldest)        */
SELECT *
FROM youngest
UNION ALL
SELECT *
FROM oldest
ORDER BY "gender", age_type DESC;