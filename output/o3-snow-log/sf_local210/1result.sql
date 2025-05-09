WITH finished_by_month AS (
    SELECT
        s."hub_id"                         AS "HUB_ID",
        o."order_created_year"             AS "YEAR",
        SUM(CASE WHEN o."order_created_month" = 2 THEN 1 ELSE 0 END) AS "FEB_FINISHED_ORDERS",
        SUM(CASE WHEN o."order_created_month" = 3 THEN 1 ELSE 0 END) AS "MAR_FINISHED_ORDERS"
    FROM
        "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"  o
        JOIN "DELIVERY_CENTER"."DELIVERY_CENTER"."STORES" s
              ON o."store_id" = s."store_id"
    WHERE
        o."order_status"       = 'FINISHED'
        AND o."order_created_month" IN (2, 3)      -- February and March
    GROUP BY
        s."hub_id",
        o."order_created_year"
),
increased_hubs AS (
    SELECT
        fbm."HUB_ID",
        fbm."YEAR",
        fbm."FEB_FINISHED_ORDERS",
        fbm."MAR_FINISHED_ORDERS",
        (fbm."MAR_FINISHED_ORDERS" - fbm."FEB_FINISHED_ORDERS")
        / fbm."FEB_FINISHED_ORDERS"       AS "PERCENT_INCREASE"
    FROM
        finished_by_month fbm
    WHERE
        fbm."FEB_FINISHED_ORDERS" > 0
        AND fbm."MAR_FINISHED_ORDERS" > fbm."FEB_FINISHED_ORDERS" * 1.20   -- > 20 % increase
)
SELECT
    ih."HUB_ID",
    h."hub_name"               AS "HUB_NAME",
    ih."YEAR",
    ih."FEB_FINISHED_ORDERS",
    ih."MAR_FINISHED_ORDERS",
    ROUND(ih."PERCENT_INCREASE", 4)   AS "PERCENT_INCREASE"
FROM
    increased_hubs ih
    JOIN "DELIVERY_CENTER"."DELIVERY_CENTER"."HUBS" h
          ON ih."HUB_ID" = h."hub_id"
ORDER BY
    ih."PERCENT_INCREASE" DESC NULLS LAST;