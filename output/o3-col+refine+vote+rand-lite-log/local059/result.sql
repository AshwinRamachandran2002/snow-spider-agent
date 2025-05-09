WITH product_totals AS (
    SELECT
        p."division",
        s."product_code",
        SUM(s."sold_quantity") AS total_qty
    FROM "hardware_fact_sales_monthly" AS s
    JOIN "hardware_dim_product"        AS p
      ON s."product_code" = p."product_code"
    WHERE s."date" BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p."division", s."product_code"
),
ranked AS (
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY division
                           ORDER BY total_qty DESC) AS rn
    FROM product_totals
)
SELECT
    division AS "Division",
    ROUND(AVG(total_qty), 4) AS "Average_Quantity_Sold_Top3_Products_2021"
FROM ranked
WHERE rn <= 3
GROUP BY division;