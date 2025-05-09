-- Average quantity sold (in 2021) of the three best-selling products within every hardware division
WITH product_totals_2021 AS (
    SELECT
        "product_code",
        SUM("sold_quantity") AS total_qty_2021
    FROM "hardware_fact_sales_monthly"
    WHERE "date" LIKE '2021-%'          -- calendar year 2021
    GROUP BY "product_code"
),
ranked_products AS (
    SELECT
        p."division",
        t."product_code",
        t.total_qty_2021,
        RANK() OVER (
            PARTITION BY p."division"
            ORDER BY t.total_qty_2021 DESC
        ) AS div_rank
    FROM product_totals_2021 t
    JOIN "hardware_dim_product" p
      ON p."product_code" = t."product_code"
)
SELECT
    "division"                         AS Division,
    AVG(total_qty_2021)               AS Avg_Qty_Top3_2021
FROM ranked_products
WHERE div_rank <= 3                   -- keep only the top-3 per division
GROUP BY "division"
ORDER BY "division";