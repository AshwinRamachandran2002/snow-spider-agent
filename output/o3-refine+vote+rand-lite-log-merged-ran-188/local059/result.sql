WITH filtered_sales AS (
    /* total quantity sold in calendar year 2021 for every product */
    SELECT
        p.division,
        s.product_code,
        SUM(s.sold_quantity) AS total_qty_2021
    FROM hardware_fact_sales_monthly AS s
    JOIN hardware_dim_product      AS p
          ON p.product_code = s.product_code
    WHERE s.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, s.product_code
),
ranked_products AS (
    /* rank products inside each division by total quantity sold */
    SELECT
        division,
        product_code,
        total_qty_2021,
        ROW_NUMBER() OVER (
            PARTITION BY division
            ORDER BY total_qty_2021 DESC, product_code
        ) AS rn
    FROM filtered_sales
)
SELECT
    division,
    AVG(total_qty_2021) AS average_quantity_top3
FROM ranked_products
WHERE rn <= 3                       -- keep only the top‑3 products per division
GROUP BY division
ORDER BY division;