SELECT
    rp."division" AS "Division",
    ROUND(AVG(s."sold_quantity"), 4) AS "Overall_Average_Quantity_Sold"
FROM
    (
        SELECT
            t."division",
            t."product_code",
            RANK() OVER (
                PARTITION BY t."division"
                ORDER BY t.total_quantity_sold DESC NULLS LAST
            ) AS product_rank
        FROM
            (
                SELECT
                    p."division",
                    s."product_code",
                    SUM(s."sold_quantity") AS total_quantity_sold
                FROM
                    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" s
                JOIN
                    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" p
                        ON s."product_code" = p."product_code"
                WHERE
                    SUBSTR(s."date", 1, 4) = '2021'
                GROUP BY
                    p."division",
                    s."product_code"
            ) t
    ) rp
JOIN
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" s
        ON rp."product_code" = s."product_code"
WHERE
    rp.product_rank <= 3
    AND SUBSTR(s."date", 1, 4) = '2021'
GROUP BY
    rp."division"
ORDER BY
    rp."division";