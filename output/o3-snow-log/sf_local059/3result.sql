WITH sales_2021 AS (   -- total quantity sold per product in calendar year 2021
    SELECT
        p."division",
        s."product_code",
        SUM(s."sold_quantity") AS "total_qty"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT      p
         ON s."product_code" = p."product_code"
    WHERE TO_DATE(s."date") BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY
        p."division",
        s."product_code"
),
ranked AS (          -- rank products within each division by total quantity
    SELECT
        "division",
        "product_code",
        "total_qty",
        DENSE_RANK() OVER (PARTITION BY "division"
                           ORDER BY "total_qty" DESC NULLS LAST) AS "rnk"
    FROM sales_2021
)
SELECT
    "division",
    AVG("total_qty") AS "average_top_3_quantity"
FROM ranked
WHERE "rnk" <= 3       -- keep only the top-3 best-selling products per division
GROUP BY "division"
ORDER BY "division";