WITH sales_with_cma AS (
    SELECT
        ms."product_id",
        ms."mth",
        ms."qty",
        (
            AVG(ms."qty") OVER (
                PARTITION BY ms."product_id"
                ORDER BY ms."mth"
                ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING
            ) +
            AVG(ms."qty") OVER (
                PARTITION BY ms."product_id"
                ORDER BY ms."mth"
                ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING
            )
        ) / 2 AS "cma"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
),
sales_ratio AS (
    SELECT
        swc."product_id",
        swc."mth",
        swc."qty",
        swc."cma",
        swc."qty" / NULLIF(swc."cma", 0) AS "sales_to_cma_ratio"
    FROM sales_with_cma swc
    WHERE swc."mth" BETWEEN '2017-01-01' AND '2017-12-31'
),
products_with_high_ratio AS (
    SELECT
        sr."product_id",
        COUNT(*) AS "months_with_high_ratio"
    FROM sales_ratio sr
    WHERE sr."sales_to_cma_ratio" >= 2
    GROUP BY sr."product_id"
)
SELECT
    p."id" AS "product_id",
    p."name" AS "product_name",
    pwhr."months_with_high_ratio"
FROM products_with_high_ratio pwhr
JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p
    ON pwhr."product_id" = p."id"
ORDER BY pwhr."months_with_high_ratio" DESC NULLS LAST;