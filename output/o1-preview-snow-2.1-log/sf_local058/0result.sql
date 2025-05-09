WITH
    "product_counts_2020" AS (
        SELECT
            HDP."segment",
            COUNT(DISTINCT HFSM."product_code") AS "unique_product_count_2020"
        FROM
            EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_DIM_PRODUCT" AS HDP
            JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" AS HFSM
                ON HDP."product_code" = HFSM."product_code"
        WHERE
            HFSM."fiscal_year" = 2020
        GROUP BY
            HDP."segment"
    ),
    "product_counts_2021" AS (
        SELECT
            HDP."segment",
            COUNT(DISTINCT HFSM."product_code") AS "unique_product_count_2021"
        FROM
            EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_DIM_PRODUCT" AS HDP
            JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."HARDWARE_FACT_SALES_MONTHLY" AS HFSM
                ON HDP."product_code" = HFSM."product_code"
        WHERE
            HFSM."fiscal_year" = 2021
        GROUP BY
            HDP."segment"
    )
SELECT
    sub."segment",
    sub."unique_product_count_2020"
FROM
    (
        SELECT
            COALESCE(pc2020."segment", pc2021."segment") AS "segment",
            COALESCE(pc2020."unique_product_count_2020", 0) AS "unique_product_count_2020",
            CASE
                WHEN pc2020."unique_product_count_2020" = 0 THEN NULL
                ELSE ROUND(
                    ((COALESCE(pc2021."unique_product_count_2021", 0) - pc2020."unique_product_count_2020") * 100.0)
                    / pc2020."unique_product_count_2020", 4)
            END AS "percentage_increase"
        FROM
            "product_counts_2020" pc2020
            FULL OUTER JOIN "product_counts_2021" pc2021
                ON pc2020."segment" = pc2021."segment"
    ) AS sub
WHERE
    sub."unique_product_count_2020" IS NOT NULL
ORDER BY
    sub."percentage_increase" DESC NULLS LAST
LIMIT 1000;