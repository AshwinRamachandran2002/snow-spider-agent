WITH gender_ages AS (
    SELECT
        "gender",
        MIN("age") AS "Youngest_Age",
        MAX("age") AS "Oldest_Age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000
      AND "age" IS NOT NULL
      AND "gender" IS NOT NULL
    GROUP BY "gender"
)
SELECT
    U."gender" AS "Gender",
    CASE
        WHEN U."age" = GA."Youngest_Age" THEN 'Youngest'
        WHEN U."age" = GA."Oldest_Age" THEN 'Oldest'
    END AS "Age_Type",
    COUNT(*) AS "Total_Number"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS U
JOIN gender_ages GA ON U."gender" = GA."gender"
WHERE U."created_at" BETWEEN 1546300800000000 AND 1651276800000000
  AND U."age" IS NOT NULL
  AND U."gender" IS NOT NULL
  AND (U."age" = GA."Youngest_Age" OR U."age" = GA."Oldest_Age")
GROUP BY U."gender", 
    CASE
        WHEN U."age" = GA."Youngest_Age" THEN 'Youngest'
        WHEN U."age" = GA."Oldest_Age" THEN 'Oldest'
    END
ORDER BY U."gender", 
    CASE
        WHEN U."age" = GA."Youngest_Age" THEN 'Youngest'
        WHEN U."age" = GA."Oldest_Age" THEN 'Oldest'
    END;