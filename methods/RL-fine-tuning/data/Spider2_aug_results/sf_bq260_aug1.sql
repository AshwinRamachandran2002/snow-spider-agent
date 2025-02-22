-- Task: From January 1, 2019, to April 30, 2022, find the youngest age for each gender in the e-commerce platform.
WITH filtered_users AS (
    SELECT 
        "first_name", 
        "last_name", 
        "gender", 
        "age",
        CAST(TO_TIMESTAMP("created_at" / 1000000.0) AS DATE) AS "created_at"
    FROM 
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE 
        CAST(TO_TIMESTAMP("created_at" / 1000000.0) AS DATE) BETWEEN '2019-01-01' AND '2022-04-30'
)
SELECT 
    "gender", 
    MIN("age") AS "youngest_age"
FROM 
    filtered_users
GROUP BY 
    "gender";