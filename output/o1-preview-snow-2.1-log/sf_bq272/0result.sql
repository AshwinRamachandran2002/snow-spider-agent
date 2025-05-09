WITH monthly_profits AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1e6), 'Mon-YYYY') AS "Month",
        p."name" AS "Product_Name",
        ROUND(SUM(oi."sale_price" - p."cost"), 4) AS "Total_Profit"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
    INNER JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p
        ON oi."product_id" = p."id"
    WHERE
        oi."status" NOT IN ('Cancelled', 'Returned')
        AND TO_TIMESTAMP(oi."created_at" / 1e6) >= TO_TIMESTAMP('2019-01-01', 'YYYY-MM-DD')
        AND TO_TIMESTAMP(oi."created_at" / 1e6) < TO_TIMESTAMP('2022-09-01', 'YYYY-MM-DD')
    GROUP BY
        "Month",
        p."name"
),
ranked_profits AS (
    SELECT
        "Month",
        "Product_Name",
        "Total_Profit",
        RANK() OVER (PARTITION BY "Month" ORDER BY "Total_Profit" DESC NULLS LAST) AS rank
    FROM
        monthly_profits
)
SELECT
    "Month",
    "Product_Name",
    "Total_Profit"
FROM
    ranked_profits
WHERE
    rank <= 3
ORDER BY
    "Month",
    rank;