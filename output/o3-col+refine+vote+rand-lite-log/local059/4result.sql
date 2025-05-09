WITH product_totals AS (
    SELECT
        hdp.division,
        hfs.product_code,
        SUM(hfs.sold_quantity) AS total_qty_2021
    FROM hardware_fact_sales_monthly AS hfs
    JOIN hardware_dim_product AS hdp
      ON hfs.product_code = hdp.product_code
    WHERE hfs.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY hdp.division, hfs.product_code
),
ranked_products AS (
    SELECT
        division,
        product_code,
        total_qty_2021,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_qty_2021 DESC) AS rn
    FROM product_totals
)
SELECT
    division,
    AVG(total_qty_2021) AS avg_qty_top3_2021
FROM ranked_products
WHERE rn <= 3
GROUP BY division;