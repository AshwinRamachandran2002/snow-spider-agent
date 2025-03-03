WITH profit_data AS (
    SELECT s."cust_id",
           SUM(s."amount_sold" - s."quantity_sold" * co."unit_cost") AS "total_profit"
    FROM "sales" AS s
    JOIN "costs" AS co 
        ON s."prod_id" = co."prod_id" AND s."time_id" = co."time_id"
    JOIN "customers" AS cu 
        ON s."cust_id" = cu."cust_id"
    WHERE cu."country_id" = (
        SELECT "country_id" FROM "countries" WHERE "country_name" = 'Italy'
    )
    AND s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s."cust_id"
),
ranked_data AS (
    SELECT
        "cust_id",
        "total_profit",
        ROW_NUMBER() OVER (ORDER BY "total_profit" DESC) AS "rn",
        COUNT(*) OVER () AS "total_customers"
    FROM profit_data
),
tiered_data AS (
    SELECT
        "cust_id",
        "total_profit",
        "rn",
        "total_customers",
        CAST((("rn" - 1) * 10) / "total_customers" + 1 AS INTEGER) AS "tier"
    FROM ranked_data
)
SELECT
    "tier",
    ROUND(MAX("total_profit"), 4) AS "Highest_Profit",
    ROUND(MIN("total_profit"), 4) AS "Lowest_Profit"
FROM tiered_data
GROUP BY "tier"
ORDER BY "tier";