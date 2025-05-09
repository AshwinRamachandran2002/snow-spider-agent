WITH date_filtered AS (
    SELECT "gender",
           "age"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE "created_at" BETWEEN 1546300800000000          -- 2019-01-01
                          AND 1651276800000000           -- 2022-04-30
),
gender_extremes AS (
    SELECT "gender",
           MIN("age") AS youngest_age,
           MAX("age") AS oldest_age
    FROM date_filtered
    GROUP BY "gender"
)
SELECT df."gender",
       SUM(CASE WHEN df."age" = ge.youngest_age THEN 1 ELSE 0 END) AS "num_at_gender_youngest_age",
       SUM(CASE WHEN df."age" = ge.oldest_age   THEN 1 ELSE 0 END) AS "num_at_gender_oldest_age"
FROM date_filtered df
JOIN gender_extremes ge
  ON df."gender" = ge."gender"
GROUP BY df."gender"
ORDER BY df."gender";