/* ------------------------------------------------------------
   Daily Manufacturing-view sales report  
   30-day look-back window : 2022-01-08  → 2022-02-06 (inclusive)
   ------------------------------------------------------------ */
WITH /* ---------- 1. inbound receipts / net-PPM ------------ */
SHIPMENTS_BY_DATE AS (
    SELECT 
        "RECEIVE_DATE"::DATE                                    AS "DATE",
        SUM("QUANTITY")                                         AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIPTS")                                     AS "NET_RECEIVED_VALUE",
        CASE WHEN SUM("QUANTITY") = 0 THEN NULL
             ELSE SUM("NET_RECEIPTS") / SUM("QUANTITY") END     AS "AVG_NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE "RECEIVE_DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "RECEIVE_DATE"
),

/* ---------- 2. sales metrics (per ASIN, per day) ----------- */
SALES_BY_SKU AS (
    SELECT 
        "DATE"::DATE                                            AS "DATE",
        "ASIN",
        SUM("ORDERED_UNITS")                                    AS "TOTAL_ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                                  AS "TOTAL_ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")                                    AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                                  AS "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

/* ---------- 3. traffic (glance views) ---------------------- */
TRAFFIC_BY_SKU AS (
    SELECT
        "DATE"::DATE                                            AS "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS")                                     AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

/* ---------- 4. inventory positions ------------------------- */
INVENTORY_BY_SKU AS (
    SELECT
        "DATE"::DATE                                            AS "DATE",
        "ASIN",
        MAX("SELLABLE_ON_HAND_UNITS" + "UNSELLABLE_ON_HAND_UNITS")                AS "TOTAL_ON_HAND_UNITS",
        MAX("SELLABLE_ON_HAND_INVENTORY" + "UNSELLABLE_ON_HAND_INVENTORY")        AS "TOTAL_ON_HAND_VALUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE", "ASIN"
),

/* ---------- 5. bring everything together ------------------- */
REPORT AS (
    SELECT
        s."DATE",
        s."ASIN",

        /* core sales metrics */
        s."TOTAL_ORDERED_UNITS",
        s."TOTAL_ORDERED_REVENUE",
        CASE WHEN s."TOTAL_ORDERED_UNITS" = 0 THEN NULL
             ELSE s."TOTAL_ORDERED_REVENUE" / s."TOTAL_ORDERED_UNITS" END         AS "AVG_SELLING_PRICE",

        /* traffic & conversion */
        t."GLANCE_VIEWS",
        CASE WHEN t."GLANCE_VIEWS" = 0 OR t."GLANCE_VIEWS" IS NULL THEN NULL
             ELSE s."TOTAL_ORDERED_UNITS" / t."GLANCE_VIEWS" END                 AS "CONVERSION_RATE",

        /* shipments (sell-through numerator) */
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE",

        /* inventory */
        i."TOTAL_ON_HAND_UNITS",
        i."TOTAL_ON_HAND_VALUE",

        /* inbound receipts / net-PPM */
        sh."NET_RECEIVED_UNITS",
        sh."NET_RECEIVED_VALUE",
        sh."AVG_NET_PPM",

        /* placeholders for metrics not available in sample data */
        NULL::FLOAT  AS "AVG_PROCURABLE_PRODUCT_OOS",
        NULL::FLOAT  AS "OPEN_PO_QTY",
        NULL::FLOAT  AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        NULL::FLOAT  AS "AVG_VENDOR_CONFIRM_RATE",
        NULL::FLOAT  AS "RECEIVE_FILL_RATE",

        /* calculated sell-through & placeholder lead time */
        CASE WHEN i."TOTAL_ON_HAND_UNITS" = 0 OR i."TOTAL_ON_HAND_UNITS" IS NULL THEN NULL
             ELSE s."SHIPPED_UNITS" / i."TOTAL_ON_HAND_UNITS" END                 AS "SELL_THROUGH_RATE",
        NULL::FLOAT  AS "VENDOR_LEAD_TIME"
    FROM SALES_BY_SKU            s
    LEFT JOIN TRAFFIC_BY_SKU     t  ON t."DATE" = s."DATE" AND t."ASIN" = s."ASIN"
    LEFT JOIN INVENTORY_BY_SKU   i  ON i."DATE" = s."DATE" AND i."ASIN" = s."ASIN"
    LEFT JOIN SHIPMENTS_BY_DATE  sh ON sh."DATE" = s."DATE"
)

/* ---------- 6. final ordered result ------------------------ */
SELECT *
FROM REPORT
ORDER BY "DATE" ASC, "ASIN"
;