SELECT
    CASE WHEN "gender" = 'M' THEN 'Male' WHEN "gender" = 'F' THEN 'Female' END AS "Gender",
    'Youngest' AS "Age_Type",
    "age" AS "Age",
    COUNT(*) AS "Count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
WHERE
    "created_at" BETWEEN 1546300800000000 AND 1651363200000000
    AND "gender" IN ('M', 'F')
    AND "age" = (
        SELECT MIN("age")
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u2
        WHERE
            u2."gender" = USERS."gender"
            AND u2."created_at" BETWEEN 1546300800000000 AND 1651363200000000
    )
GROUP BY "Gender", "Age"

UNION ALL

SELECT
    CASE WHEN "gender" = 'M' THEN 'Male' WHEN "gender" = 'F' THEN 'Female' END AS "Gender",
    'Oldest' AS "Age_Type",
    "age" AS "Age",
    COUNT(*) AS "Count"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
WHERE
    "created_at" BETWEEN 1546300800000000 AND 1651363200000000
    AND "gender" IN ('M', 'F')
    AND "age" = (
        SELECT MAX("age")
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u2
        WHERE
            u2."gender" = USERS."gender"
            AND u2."created_at" BETWEEN 1546300800000000 AND 1651363200000000
    )
GROUP BY "Gender", "Age";