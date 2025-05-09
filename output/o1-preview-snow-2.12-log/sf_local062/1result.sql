WITH customer_profits AS (
    SELECT
        "S"."cust_id",
        SUM("S"."quantity_sold" * ("CST"."unit_price" - "CST"."unit_cost")) AS "total_profit"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" AS "S"
    JOIN
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" AS "C"
        ON "S"."cust_id" = "C"."cust_id"
    JOIN
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" AS "CO"
        ON "C"."country_id" = "CO"."country_id"
    JOIN
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" AS "T"
        ON "S"."time_id" = "T"."time_id"
    JOIN
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" AS "CST"
        ON "S"."prod_id" = "CST"."prod_id"
        AND "S"."time_id" = "CST"."time_id"
        AND "S"."promo_id" = "CST"."promo_id"
        AND "S"."channel_id" = "CST"."channel_id"
    WHERE
        "CO"."country_name" = 'Italy'
        AND "T"."calendar_month_number" = 12
        AND "T"."calendar_year" = 2021
    GROUP BY
        "S"."cust_id"
),
min_max_profits AS (
    SELECT
        MIN("total_profit") AS "min_profit",
        MAX("total_profit") AS "max_profit"
    FROM
        customer_profits
),
customer_buckets AS (
    SELECT
        cp."cust_id",
        cp."total_profit",
        CASE
            WHEN mm."max_profit" = mm."min_profit" THEN 1
            ELSE LEAST(10, FLOOR(( (cp."total_profit" - mm."min_profit") / NULLIF(mm."max_profit" - mm."min_profit", 0) ) * 10) + 1)
        END AS "Bucket_Number"
    FROM
        customer_profits cp
    CROSS JOIN
        min_max_profits mm
)
SELECT
    "Bucket_Number",
    COUNT(*) AS "Number_of_Customers",
    ROUND(MIN("total_profit"), 4) AS "Min_Total_Profit",
    ROUND(MAX("total_profit"), 4) AS "Max_Total_Profit"
FROM
    customer_buckets
GROUP BY
    "Bucket_Number"
ORDER BY
    "Bucket_Number";