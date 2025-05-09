WITH order_sales_2020 AS (
    /* 1.  Order‐item rows that represent an actual sale in 2020
           (ignore cancelled orders).                              */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("created_at" / 1000000)
                  )                                   AS "sale_month",
        "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2020
      AND "status" <> 'Cancelled'
      AND "product_id" IS NOT NULL
),
product_profit AS (
    /* 2.  Profit (retail – cost) for every product. */
    SELECT
        "id"                    AS "product_id",
        "name"                  AS "product_name",
        ("retail_price" - "cost") AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
),
monthly_profits AS (
    /* 3.  Attach profit to each (month, product) that had a sale. */
    SELECT
        os."sale_month",
        pp."product_name",
        pp."profit",
        MIN(pp."profit") OVER (PARTITION BY os."sale_month") AS "min_profit_in_month"
    FROM order_sales_2020   os
    JOIN product_profit     pp
          ON os."product_id" = pp."product_id"
),
lowest_profit_products AS (
    /* 4.  Keep only the product(s) that have the lowest profit in each month. */
    SELECT DISTINCT
        "sale_month",
        "product_name"
    FROM monthly_profits
    WHERE "profit" = "min_profit_in_month"
)

SELECT
    TO_CHAR("sale_month", 'YYYY-MM') AS "month",
    "product_name"
FROM lowest_profit_products
ORDER BY "sale_month";