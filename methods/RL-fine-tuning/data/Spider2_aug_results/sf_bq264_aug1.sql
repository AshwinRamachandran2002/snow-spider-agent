-- Task: List all the youngest and oldest users registered between January 1, 2019, and April 30, 2022, from our e-commerce platform data.
WITH youngest AS (
    SELECT
        "gender",
        "id",
        "first_name",
        "last_name",
        "age",
        'youngest' AS "tag"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE
        "age" = (SELECT MIN("age") FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS")
        AND TO_TIMESTAMP("created_at" / 1000000.0) BETWEEN TO_TIMESTAMP('2019-01-01') AND TO_TIMESTAMP('2022-04-30')
    GROUP BY
        "gender", "id", "first_name", "last_name", "age"
),
oldest AS (
    SELECT
        "gender",
        "id",
        "first_name",
        "last_name",
        "age",
        'oldest' AS "tag"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
    WHERE
        "age" = (SELECT MAX("age") FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS")
        AND TO_TIMESTAMP("created_at" / 1000000.0) BETWEEN TO_TIMESTAMP('2019-01-01') AND TO_TIMESTAMP('2022-04-30')
    GROUP BY
        "gender", "id", "first_name", "last_name", "age"
)
SELECT * FROM youngest
UNION ALL
SELECT * FROM oldest;