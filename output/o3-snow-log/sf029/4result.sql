/* -----------------------------------------------------------
   Daily Manufacturing-level detailed sales report
   Window : 2022-01-08  →  2022-02-06   (30 days, inclusive)
-------------------------------------------------------------*/
WITH
/* 1)  Sales ­– aggregate to one row per DATE / ASIN */
sales_30 AS (
    SELECT
        DATE_TRUNC('day', "DATE")                       AS "DATE",
        "ASIN",
        MIN("PRODUCT_TITLE")                            AS "PRODUCT_TITLE",
        SUM("ORDERED_UNITS")        AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")      AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")        AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")      AS "SHIPPED_REVENUE"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2
),

/* 2)  Traffic */
traffic_30 AS (
    SELECT
        DATE_TRUNC('day', "DATE")  AS "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS")        AS "GLANCE_VIEWS"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2
),

/* 3)  Inventory (take the latest snapshot per day/ASIN) */
inventory_30 AS (
    SELECT
        DATE_TRUNC('day', "DATE")                         AS "DATE",
        "ASIN",
        MAX("SELLABLE_ON_HAND_UNITS")       AS "SELLABLE_ON_HAND_UNITS",
        MAX("UNSELLABLE_ON_HAND_UNITS")     AS "UNSELLABLE_ON_HAND_UNITS",
        MAX("SELLABLE_ON_HAND_INVENTORY")   AS "SELLABLE_ON_HAND_INVENTORY",
        MAX("UNSELLABLE_ON_HAND_INVENTORY") AS "UNSELLABLE_ON_HAND_INVENTORY"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2
),

/* 4)  Distributor-shipment data → proxy for Net PPM / Receipts
      (no ASIN available → aggregate by day) */
shipment_30 AS (
    SELECT
        DATE_TRUNC('day', "RECEIVE_DATE")                              AS "DATE",
        AVG( CASE WHEN "QUANTITY" <> 0 
                  THEN "NET_RECEIPTS" / "QUANTITY" END )              AS "AVG_NET_PPM",
        SUM("QUANTITY")                                                AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIPTS")                                            AS "NET_RECEIVED_VALUE"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE  "RECEIVE_DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1
)

/* 5)  Assemble the daily report */
SELECT
    s."DATE",
    s."ASIN",
    s."PRODUCT_TITLE",
    /* ----------  Sales & Price ---------- */
    s."ORDERED_UNITS"                                AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE"                              AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" <> 0
         THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
    END                                              AS "AVG_SELLING_PRICE",
    /* ----------  Traffic ---------- */
    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" <> 0
         THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
    END                                              AS "CONVERSION_RATE",
    /* ----------  Shipments ---------- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",
    /* ----------  Net PPM / Receipts ---------- */
    sh."AVG_NET_PPM",
    sh."NET_RECEIVED_UNITS",
    sh."NET_RECEIVED_VALUE",
    /* ----------  Inventory ---------- */
    (i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")            AS "TOTAL_ON_HAND_UNITS",
    (i."SELLABLE_ON_HAND_INVENTORY" + i."UNSELLABLE_ON_HAND_INVENTORY")    AS "TOTAL_ON_HAND_VALUE",
    /* ----------  Derived / placeholder KPIs (not in sample data) ---------- */
    CAST(NULL AS FLOAT)  AS "AVG_PROCUREABLE_PRODUCT_OOS",
    CAST(NULL AS FLOAT)  AS "OPEN_PO_QUANTITY",
    CAST(NULL AS FLOAT)  AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
    CAST(NULL AS FLOAT)  AS "AVG_VENDOR_CONFIRMATION_RATE",
    CAST(NULL AS FLOAT)  AS "AVG_RECEIVE_FILL_RATE",
    /* Sell-through = shipped units ÷ (on-hand + shipped) */
    CASE 
         WHEN (i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS" + s."SHIPPED_UNITS") <> 0
         THEN s."SHIPPED_UNITS" /
              (i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS" + s."SHIPPED_UNITS")
    END                             AS "SELL_THROUGH_RATE",
    CAST(NULL AS FLOAT)  AS "AVG_VENDOR_LEAD_TIME_DAYS"
FROM        sales_30      s
LEFT JOIN   traffic_30    t   ON  t."DATE" = s."DATE"  AND t."ASIN" = s."ASIN"
LEFT JOIN   inventory_30  i   ON  i."DATE" = s."DATE"  AND i."ASIN" = s."ASIN"
LEFT JOIN   shipment_30   sh  ON  sh."DATE" = s."DATE"
ORDER BY     s."DATE" ASC,
             s."ASIN" ASC;