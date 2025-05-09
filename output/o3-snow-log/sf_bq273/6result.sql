WITH monthly_profit AS (
    /*----------------------------------------------------------
      Profit by delivery month for Facebook-sourced, COMPLETED
      order-items whose parent orders were created from
      Aug-2022 through Nov-2023.
    ----------------------------------------------------------*/
    SELECT
        /* First day of the delivery month */
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ( oi."delivered_at" / 1000000 )
        )::DATE                                AS "month",
        SUM( oi."sale_price" - ii."cost" )      AS "profit"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS     AS oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS AS ii
          ON oi."inventory_item_id" = ii."id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS          AS o
          ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS           AS u
          ON oi."user_id" = u."id"
    WHERE u."traffic_source" = 'Facebook'
      AND oi."status"        = 'Complete'
      AND o."created_at" BETWEEN 1659312000000000              -- 2022-08-01
                            AND 1701302400000000              -- 2023-11-30
      AND oi."delivered_at"  IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_NTZ( oi."delivered_at" / 1000000 ))
            BETWEEN '2022-08-01'::DATE AND '2023-11-30'::DATE
    GROUP BY 1
),

profit_change AS (
    SELECT
        "month",
        "profit",
        "profit" - LAG("profit") OVER (ORDER BY "month") AS "profit_increase"
    FROM   monthly_profit
)

SELECT
    "month",
    ROUND("profit",4)          AS "profit",
    ROUND("profit_increase",4) AS "profit_increase"
FROM   profit_change
WHERE  "profit_increase" IS NOT NULL
ORDER  BY "profit_increase" DESC NULLS LAST
LIMIT 5;