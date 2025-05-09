WITH product_sales_2021 AS (
    /* total quantity sold per product in calendar year 2021 */
    SELECT
        p."division" AS division,
        s."product_code" AS product_code,
        SUM(s."sold_quantity") AS total_qty
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
      ON s."product_code" = p."product_code"
    WHERE YEAR(TO_DATE(s."date")) = 2021          -- calendar year filter
    GROUP BY
        p."division",
        s."product_code"
),
top3 AS (
    /* pick the top-3 best-selling products (by total quantity) within each division */
    SELECT
        division,
        product_code,
        total_qty,
        ROW_NUMBER() OVER (
            PARTITION BY division
            ORDER BY total_qty DESC NULLS LAST
        ) AS rn
    FROM product_sales_2021
    QUALIFY rn <= 3
),
division_avg AS (
    /* average of those three total quantities per division */
    SELECT
        division,
        AVG(total_qty) AS avg_quantity
    FROM top3
    GROUP BY division
)
SELECT
    division,
    ROUND(avg_quantity, 4) AS avg_quantity
FROM division_avg
ORDER BY division;