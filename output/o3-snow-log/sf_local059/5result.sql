WITH sales_2021 AS (   -- total quantity per product in calendar year 2021
    SELECT
        p."division",
        s."product_code",
        SUM(s."sold_quantity") AS total_qty
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT       p
          ON s."product_code" = p."product_code"
    WHERE YEAR( TO_DATE( s."date" ) ) = 2021
    GROUP BY
        p."division",
        s."product_code"
),
ranked AS (            -- rank products within each division by total quantity
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY "division"
                           ORDER BY total_qty DESC NULLS LAST) AS rnk
    FROM sales_2021
),
top3 AS (              -- keep top-3 products of every division
    SELECT
        "division",
        total_qty
    FROM ranked
    WHERE rnk <= 3
)
SELECT                  -- overall average quantity of those top-3 products
    "division",
    AVG(total_qty) AS average_quantity_sold
FROM top3
GROUP BY "division"
ORDER BY average_quantity_sold DESC NULLS LAST;