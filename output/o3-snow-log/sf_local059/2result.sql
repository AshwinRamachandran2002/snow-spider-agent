WITH product_sales_2021 AS (
    /* 1.  Total quantity sold per product in calendar (fiscal) year 2021 */
    SELECT
        hdp."division",
        hfs."product_code",
        SUM(hfs."sold_quantity") AS total_quantity
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" hfs
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_DIM_PRODUCT"          hdp
          ON hfs."product_code" = hdp."product_code"
    WHERE hfs."fiscal_year" = 2021
    GROUP BY
        hdp."division",
        hfs."product_code"
),

ranked_products AS (
    /* 2. Rank products within each division by total quantity sold */
    SELECT
        ps."division",
        ps."product_code",
        ps.total_quantity,
        DENSE_RANK() OVER (PARTITION BY ps."division"
                           ORDER BY ps.total_quantity DESC NULLS LAST) AS rnk
    FROM product_sales_2021 ps
),

top_three AS (
    /* 3. Keep only the top-3 products per division */
    SELECT
        "division",
        total_quantity
    FROM ranked_products
    WHERE rnk <= 3
)

-- 4. Average quantity of those top-3 products for each division
SELECT
    "division",
    AVG(total_quantity) AS avg_quantity_top3
FROM top_three
GROUP BY
    "division"
ORDER BY
    "division";