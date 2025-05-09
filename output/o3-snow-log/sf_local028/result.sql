WITH "months" AS (               -- generate rows for the 12 months
    SELECT SEQ4() + 1 AS "month_num"
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
"delivered" AS (                 -- delivered orders with valid dates
    SELECT
        TO_DATE(TRY_TO_TIMESTAMP("order_delivered_customer_date")) AS "delivered_date"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
      AND TRY_TO_TIMESTAMP("order_delivered_customer_date") IS NOT NULL
      AND EXTRACT(YEAR FROM TRY_TO_TIMESTAMP("order_delivered_customer_date")) IN (2016, 2017, 2018)
)
SELECT
    "m"."month_num"                                                       AS "Month",
    SUM(CASE WHEN EXTRACT(YEAR FROM "d"."delivered_date") = 2016 THEN 1 ELSE 0 END) AS "2016",
    SUM(CASE WHEN EXTRACT(YEAR FROM "d"."delivered_date") = 2017 THEN 1 ELSE 0 END) AS "2017",
    SUM(CASE WHEN EXTRACT(YEAR FROM "d"."delivered_date") = 2018 THEN 1 ELSE 0 END) AS "2018"
FROM "months" AS "m"
LEFT JOIN "delivered" AS "d"
       ON EXTRACT(MONTH FROM "d"."delivered_date") = "m"."month_num"
GROUP BY "m"."month_num"
ORDER BY "m"."month_num" NULLS LAST;