WITH "age_extremes" AS (
    SELECT "gender", MIN("age") AS "youngest_age", MAX("age") AS "oldest_age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
    GROUP BY "gender"
)
SELECT
    U."gender" AS "Gender",
    CASE
        WHEN U."age" = A."youngest_age" THEN 'Youngest'
        WHEN U."age" = A."oldest_age" THEN 'Oldest'
    END AS "Age_Type",
    COUNT(*) AS "Total_Number"
FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" U
JOIN
    "age_extremes" A
ON
    U."gender" = A."gender"
WHERE
    U."created_at" BETWEEN 1546300800000000 AND 1651276800000000
    AND (U."age" = A."youngest_age" OR U."age" = A."oldest_age")
GROUP BY
    U."gender",
    CASE
        WHEN U."age" = A."youngest_age" THEN 'Youngest'
        WHEN U."age" = A."oldest_age" THEN 'Oldest'
    END;