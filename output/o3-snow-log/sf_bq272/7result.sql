/*  Top-3 most-profitable products per month
    (Jan-2019 – Aug-2022, Snowflake dialect)               */

WITH valid_items AS (          -- 1.  keep only shipped/completed items
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000))  AS "month",
        "oi"."product_id",
        SUM("oi"."sale_price")                                         AS "sales",
        SUM("ii"."cost")                                               AS "cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS       AS "oi"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS   AS "ii"
          ON  "oi"."inventory_item_id" = "ii"."id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS            AS "o"
          ON  "oi"."order_id" = "o"."order_id"
    WHERE
          COALESCE("oi"."status",'') NOT IN ('Cancelled','Returned')
      AND COALESCE("o"."status",'')  NOT IN ('Cancelled','Returned')
      AND "oi"."returned_at" IS NULL
      AND "o"."returned_at"  IS NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP("oi"."created_at" / 1000000))
          BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP BY 1,2
),  

profit_by_product AS (         -- 2.  profit per product & month
    SELECT
        "month",
        "product_id",
        SUM("sales") - SUM("cost")   AS "profit"
    FROM   valid_items
    GROUP BY 1,2
),  

ranked AS (                    -- 3.  rank products inside each month
    SELECT
        pb."month",
        p."name"                       AS "product_name",
        pb."profit",
        ROW_NUMBER() OVER (PARTITION BY pb."month"
                           ORDER BY pb."profit" DESC NULLS LAST) AS "rnk"
    FROM  profit_by_product pb
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS  p
          ON pb."product_id" = p."id"
)

-- 4.  deliver the required list
SELECT
    TO_CHAR("month",'YYYY-MM') AS "month",
    "product_name",
    ROUND("profit", 4)         AS "profit"
FROM   ranked
WHERE  "rnk" <= 3
ORDER  BY "month", "rnk";