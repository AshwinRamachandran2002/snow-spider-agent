WITH sales_2021 AS (            -- total quantity per product in calendar year 2021
    SELECT
        p."division"                    AS division,      -- unquoted alias
        s."product_code"                AS product_code,  -- unquoted alias
        SUM(s."sold_quantity")          AS total_qty
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
          ON s."product_code" = p."product_code"
    WHERE TO_DATE(s."date") BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p."division", s."product_code"
),
ranked_products AS (            -- rank products by total quantity within each division
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY division
                           ORDER BY total_qty DESC NULLS LAST) AS rn
    FROM sales_2021
),
top3 AS (                       -- keep only the top-3 products of each division
    SELECT
        division,
        total_qty
    FROM ranked_products
    WHERE rn <= 3
)
SELECT                          -- average quantity sold of those top-3 products
    division,
    ROUND(AVG(total_qty), 4) AS avg_quantity_sold_top3
FROM top3
GROUP BY division
ORDER BY division NULLS LAST;