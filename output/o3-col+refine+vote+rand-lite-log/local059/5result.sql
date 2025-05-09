WITH product_totals AS (
    SELECT
        p."division",
        s."product_code",
        SUM(s."sold_quantity") AS total_qty_2021
    FROM "hardware_fact_sales_monthly" AS s
    JOIN "hardware_dim_product"       AS p
         ON s."product_code" = p."product_code"
    WHERE substr(s."date",1,4) = '2021'            -- calendar year 2021
    GROUP BY p."division", s."product_code"
),
ranked AS (
    SELECT
        pt.*,
        ROW_NUMBER() OVER (PARTITION BY pt."division"
                           ORDER BY pt.total_qty_2021 DESC) AS rn
    FROM product_totals AS pt
)
SELECT
    "division",
    ROUND(AVG(total_qty_2021), 4) AS overall_avg_qty_top3_2021
FROM ranked
WHERE rn <= 3                                   -- keep only top-3 per division
GROUP BY "division";