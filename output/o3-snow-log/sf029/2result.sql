/*  Daily manufacturing report – 30-day window ending 06-Feb-2022  */
WITH date_window                       AS (
    SELECT
        TO_DATE('2022-01-08') AS start_date,
        TO_DATE('2022-02-06') AS end_date
),

/*-------------- 1.  SALES ----------------*/
sales_aggr                            AS (
    SELECT
        CAST("DATE" AS DATE)                       AS "DATE",
        "ASIN",
        SUM("ORDERED_UNITS")                       AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                     AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")                       AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                     AS "SHIPPED_REVENUE",
        SUM("SHIPPED_COGS")                        AS "SHIPPED_COGS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES" s
    JOIN date_window dw
      ON CAST(s."DATE" AS DATE) BETWEEN dw.start_date AND dw.end_date
    WHERE s."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/*-------------- 2.  TRAFFIC ---------------*/
traffic_aggr                          AS (
    SELECT
        CAST("DATE" AS DATE)                       AS "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS")                        AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC" t
    JOIN date_window dw
      ON CAST(t."DATE" AS DATE) BETWEEN dw.start_date AND dw.end_date
    WHERE t."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/*-------------- 3.  INVENTORY -------------*/
inventory_aggr                        AS (
    SELECT
        CAST("DATE" AS DATE)                       AS "DATE",
        "ASIN",
        AVG("SELLABLE_ON_HAND_UNITS")              AS "ON_HAND_UNITS",
        AVG("SELLABLE_ON_HAND_INVENTORY")          AS "ON_HAND_VALUE",
        AVG("UNSELLABLE_ON_HAND_UNITS")            AS "UNSELLABLE_UNITS",
        AVG("UNSELLABLE_ON_HAND_INVENTORY")        AS "UNSELLABLE_VALUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY" i
    JOIN date_window dw
      ON CAST(i."DATE" AS DATE) BETWEEN dw.start_date AND dw.end_date
    WHERE i."DISTRIBUTOR_VIEW" = 'Manufacturing'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/*-------------- 4.  NET-PPM / RECEIPTS ----*/
shipment_aggr                        AS (
    /*  distributor-level receipts – no ASIN granularity available  */
    SELECT
        CAST("RECEIVE_DATE" AS DATE)               AS "DATE",
        SUM("QUANTITY")                            AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIPTS")                        AS "NET_RECEIVED_VALUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    JOIN date_window dw
      ON CAST("RECEIVE_DATE" AS DATE) BETWEEN dw.start_date AND dw.end_date
    GROUP BY CAST("RECEIVE_DATE" AS DATE)
),

/*-------------- 5.  FINAL JOIN ------------*/
main_join                               AS (
    SELECT
        s."DATE",
        s."ASIN",

        /* sales */
        s."ORDERED_UNITS"                           AS "TOTAL_ORDERED_UNITS",
        s."ORDERED_REVENUE"                         AS "TOTAL_ORDERED_REVENUE",
        CASE WHEN s."ORDERED_UNITS" > 0
             THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
        END                                         AS "AVG_SELLING_PRICE",

        /* traffic  */
        t."GLANCE_VIEWS"                            AS "GLANCE_VIEWS",
        CASE WHEN t."GLANCE_VIEWS" > 0
             THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
        END                                         AS "CONVERSION_RATE",

        /* shipped  */
        s."SHIPPED_UNITS"                           AS "SHIPPED_UNITS",
        s."SHIPPED_REVENUE"                         AS "SHIPPED_REVENUE",

        /* net-PPM proxy (revenue – COGS) */
        s."SHIPPED_REVENUE" - s."SHIPPED_COGS"      AS "NET_PPM_VALUE",

        /* inventory  */
        i."ON_HAND_UNITS"                           AS "ON_HAND_UNITS",
        i."ON_HAND_VALUE"                           AS "ON_HAND_VALUE",
        CASE WHEN NVL(i."ON_HAND_UNITS",0)=0
             THEN 1 ELSE 0
        END                                         AS "PROC_PRODUCT_OOS_FLAG",

        /* distributor receipts (not ASIN-specific) */
        sh."NET_RECEIVED_UNITS",
        sh."NET_RECEIVED_VALUE",

        /* fulfilment gap */
        (s."ORDERED_UNITS" - s."SHIPPED_UNITS")     AS "UNFILLED_CUSTOMER_ORDERED_UNITS",

        /* placeholders for metrics not present in sample data */
        NULL::NUMBER                                AS "OPEN_PURCHASE_ORDER_QTY",
        NULL::FLOAT                                 AS "AVG_VENDOR_CONFIRM_RATE",
        NULL::FLOAT                                 AS "AVG_RECEIVE_FILL_RATE",
        NULL::FLOAT                                 AS "AVG_SELL_THROUGH_RATE",
        NULL::FLOAT                                 AS "AVG_VENDOR_LEAD_TIME_DAYS"
    FROM sales_aggr      s
    LEFT JOIN traffic_aggr    t
           ON s."DATE" = t."DATE"
          AND s."ASIN" = t."ASIN"
    LEFT JOIN inventory_aggr  i
           ON s."DATE" = i."DATE"
          AND s."ASIN" = i."ASIN"
    LEFT JOIN shipment_aggr   sh
           ON s."DATE" = sh."DATE"
)

SELECT *
FROM main_join
ORDER BY "DATE" ASC, "ASIN" ASC;