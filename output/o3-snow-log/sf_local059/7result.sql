WITH sales_2021 AS (
    SELECT
        "product_code",
        SUM("sold_quantity") AS total_qty
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY
    WHERE YEAR(TO_DATE("date")) = 2021
    GROUP BY "product_code"
),
prod_sales AS (
    SELECT
        p."division",
        s."product_code",
        s.total_qty
    FROM sales_2021 s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
      ON s."product_code" = p."product_code"
),
ranked AS (
    SELECT
        "division",
        "product_code",
        total_qty,
        DENSE_RANK() OVER (PARTITION BY "division" ORDER BY total_qty DESC NULLS LAST) AS rnk
    FROM prod_sales
)
SELECT
    "division",
    ROUND(AVG(total_qty), 4) AS avg_quantity_sold
FROM ranked
WHERE rnk <= 3
GROUP BY "division"
ORDER BY "division";