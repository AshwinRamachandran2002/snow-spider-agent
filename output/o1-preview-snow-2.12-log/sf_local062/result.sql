WITH customer_profits AS (
    SELECT
        s."cust_id",
        SUM(s."quantity_sold" * (c."unit_price" - c."unit_cost")) AS "total_profit"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" cust
            ON s."cust_id" = cust."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" countries
            ON cust."country_id" = countries."country_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" c
            ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t
            ON s."time_id" = t."time_id"
    WHERE
        countries."country_name" ILIKE '%Italy%'
        AND t."calendar_month_number" = 12
        AND t."calendar_year" = 2021
    GROUP BY
        s."cust_id"
),
profit_range AS (
    SELECT
        MIN("total_profit") AS "min_profit",
        MAX("total_profit") AS "max_profit"
    FROM
        customer_profits
),
bucketed_profits AS (
    SELECT
        cp."cust_id",
        cp."total_profit",
        CASE
            WHEN pr."max_profit" = pr."min_profit" THEN 1
            ELSE LEAST(10, GREATEST(1, CEIL( ((cp."total_profit" - pr."min_profit") / NULLIF( (pr."max_profit" - pr."min_profit"), 0) ) * 10 )))
        END AS "Bucket_Number"
    FROM
        customer_profits cp
        CROSS JOIN profit_range pr
)
SELECT
    bp."Bucket_Number",
    COUNT(*) AS "Number_of_Customers",
    ROUND(MIN(bp."total_profit"), 4) AS "Min_Total_Profit",
    ROUND(MAX(bp."total_profit"), 4) AS "Max_Total_Profit"
FROM
    bucketed_profits bp
GROUP BY
    bp."Bucket_Number"
ORDER BY
    bp."Bucket_Number";