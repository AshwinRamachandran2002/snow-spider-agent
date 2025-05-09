WITH sales_2020 AS (
    /* All order–item rows created in 2020                                    */
    SELECT
        TO_CHAR(TO_TIMESTAMP("created_at" / 1000000), 'YYYY-MM') AS "MONTH",
        "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "created_at" BETWEEN 1577836800000000     -- 2020‑01‑01 00:00:00
                          AND 1609459199000000     -- 2020‑12‑31 23:59:59
          AND "product_id" IS NOT NULL
),

product_profit AS (
    /* Profit for every product (retail price − cost)                        */
    SELECT
        "id"                           AS "PRODUCT_ID",
        "name"                         AS "PRODUCT_NAME",
        ("retail_price" - "cost")      AS "PROFIT"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
    WHERE "retail_price" IS NOT NULL
      AND "cost" IS NOT NULL
),

month_min_profit AS (
    /* Minimum profit observed in each month of 2020                         */
    SELECT
        s."MONTH",
        MIN(p."PROFIT") AS "MIN_PROFIT"
    FROM sales_2020 s
    JOIN product_profit p
      ON s."product_id" = p."PRODUCT_ID"
    GROUP BY s."MONTH"
),

products_lowest_profit AS (
    /* Products whose profit equals the monthly minimum                      */
    SELECT DISTINCT
        m."MONTH",
        p."PRODUCT_NAME"
    FROM month_min_profit m
    JOIN sales_2020      s ON m."MONTH" = s."MONTH"
    JOIN product_profit  p ON s."product_id" = p."PRODUCT_ID"
    WHERE p."PROFIT" = m."MIN_PROFIT"
)

/* Final list: products with the lowest profit for each month of 2020        */
SELECT
    "MONTH",
    "PRODUCT_NAME"
FROM products_lowest_profit
ORDER BY
    "MONTH" ASC,
    "PRODUCT_NAME" ASC;