/*  Youngest vs. Oldest user counts (per gender) between
    2019-01-01 00:00:00 and 2022-04-30 23:59:59  */

SELECT
    "gender",
    SUM(CASE WHEN "age_group" = 'youngest' THEN "cnt" END) AS "youngest_user_cnt",
    SUM(CASE WHEN "age_group" = 'oldest'  THEN "cnt" END) AS "oldest_user_cnt"
FROM (
        /* youngest-age users */
        SELECT
            "gender",
            'youngest' AS "age_group",
            COUNT(*)   AS "cnt"
        FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
        WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
          AND "age" = (
                SELECT MIN("age")
                FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
                WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
          )
        GROUP BY "gender"

        UNION ALL

        /* oldest-age users */
        SELECT
            "gender",
            'oldest'  AS "age_group",
            COUNT(*)  AS "cnt"
        FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
        WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
          AND "age" = (
                SELECT MAX("age")
                FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
                WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
          )
        GROUP BY "gender"
) AS "age_counts"
GROUP BY "gender"
ORDER BY "gender";