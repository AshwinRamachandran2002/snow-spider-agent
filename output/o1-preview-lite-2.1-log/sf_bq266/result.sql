WITH avg_profit_margin AS (
    SELECT
        P."name",
        DATE_TRUNC('MONTH', TO_TIMESTAMP(O."created_at" / 1e6)) AS "month",
        ROUND(AVG((O."sale_price" - P."cost") / O."sale_price"), 4) AS "average_profit_margin"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" O
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" P
    ON
        O."product_id" = P."id"
    WHERE
        O."sale_price" > 0
        AND TO_TIMESTAMP(O."created_at" / 1e6) >= '2020-01-01'
        AND TO_TIMESTAMP(O."created_at" / 1e6) < '2021-01-01'
    GROUP BY
        P."name",
        "month"
),
ranked_profit_margin AS (
    SELECT
        A.*,
        ROW_NUMBER() OVER (
            PARTITION BY A."month"
            ORDER BY A."average_profit_margin" ASC, A."name" ASC
        ) AS rn
    FROM
        avg_profit_margin A
)
SELECT
    "month",
    "name",
    "average_profit_margin"
FROM
    ranked_profit_margin
WHERE
    rn = 1
ORDER BY
    "month" ASC;