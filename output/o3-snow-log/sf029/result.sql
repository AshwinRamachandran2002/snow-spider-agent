/*  Daily Manufacturing sales report – 30-day window that ends 06-Feb-2022  */
WITH
/*---------------------------------------------------------------------------
1. Aggregate SALES (ordered / shipped) per calendar-day & ASIN
---------------------------------------------------------------------------*/
sales AS (
    SELECT
        CAST("DATE" AS DATE)                        AS "DATE",
        "ASIN",
        COALESCE("PROGRAM" , '')                   AS "PROGRAM",
        COALESCE("PERIOD"  , '')                   AS "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("ORDERED_UNITS")   AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE") AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")   AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE") AS "SHIPPED_REVENUE"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" >= '2022-01-07'
      AND  "DATE" <  '2022-02-07'          -- 30-day window (inclusive of 06-Feb-2022)
    GROUP  BY 1,2,3,4,5
),

/*---------------------------------------------------------------------------
2. Aggregate TRAFFIC (glance views) for the same grain
---------------------------------------------------------------------------*/
traffic AS (
    SELECT
        CAST("DATE" AS DATE)                      AS "DATE",
        "ASIN",
        ''                                        AS "PROGRAM",      -- not present in traffic
        COALESCE("PERIOD", '')                   AS "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("GLANCE_VIEWS")                      AS "GLANCE_VIEWS"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" >= '2022-01-07'
      AND  "DATE" <  '2022-02-07'
    GROUP  BY 1,2,3,4,5
),

/*---------------------------------------------------------------------------
3. Aggregate INVENTORY (on-hand units & $) for the same grain
---------------------------------------------------------------------------*/
inv AS (
    SELECT
        CAST("DATE" AS DATE)                                        AS "DATE",
        "ASIN",
        ''                                                          AS "PROGRAM",
        ''                                                          AS "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("SELLABLE_ON_HAND_UNITS" + "UNSELLABLE_ON_HAND_UNITS")         AS "ON_HAND_UNITS",
        SUM("SELLABLE_ON_HAND_INVENTORY" + "UNSELLABLE_ON_HAND_INVENTORY") AS "ON_HAND_VALUE"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE  "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND  "DATE" >= '2022-01-07'
      AND  "DATE" <  '2022-02-07'
    GROUP  BY 1,2,3,4,5
),

/*---------------------------------------------------------------------------
4. Aggregate RECEIPTS (net received units & value) – no ASIN granularity
---------------------------------------------------------------------------*/
receipts AS (
    SELECT
        CAST("RECEIVE_DATE" AS DATE) AS "DATE",
        SUM("QUANTITY")             AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIPTS")         AS "NET_RECEIVED_VALUE"
    FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE  "RECEIVE_DATE" >= '2022-01-07'
      AND  "RECEIVE_DATE" <  '2022-02-07'
    GROUP  BY 1
)

/*---------------------------------------------------------------------------
5. Combine all sources
---------------------------------------------------------------------------*/
SELECT
       s."DATE",
       s."ASIN",
       s."PROGRAM",
       s."PERIOD",
       s."DISTRIBUTOR_VIEW",

       /* ---------- Sales ---------- */
       s."ORDERED_UNITS",
       s."ORDERED_REVENUE",
       CASE WHEN s."ORDERED_UNITS" > 0
            THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
       END                                        AS "AVG_SELLING_PRICE",

       /* ---------- Traffic ---------- */
       t."GLANCE_VIEWS",
       CASE WHEN t."GLANCE_VIEWS" > 0
            THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
       END                                        AS "CONVERSION_RATE",

       /* ---------- Ship ---------- */
       s."SHIPPED_UNITS",
       s."SHIPPED_REVENUE",

       /* ---------- Receipts ---------- */
       r."NET_RECEIVED_UNITS",
       r."NET_RECEIVED_VALUE",

       /* ---------- Inventory ---------- */
       i."ON_HAND_UNITS",
       i."ON_HAND_VALUE",

       /* ---------- Place-holders for metrics not available in sample data ---------- */
       CAST(NULL AS FLOAT)  AS "AVG_NET_PPM",
       CAST(NULL AS FLOAT)  AS "AVG_PROCURABLE_OOS",
       CAST(NULL AS FLOAT)  AS "OPEN_PO_QTY",
       CAST(NULL AS FLOAT)  AS "UNFILLED_CUSTOMER_ORDER_UNITS",
       CAST(NULL AS FLOAT)  AS "AVG_VENDOR_CONFIRMATION_RATE",
       CAST(NULL AS FLOAT)  AS "AVG_RECEIVE_FILL_RATE",
       CAST(NULL AS FLOAT)  AS "SELL_THROUGH_RATE",
       CAST(NULL AS FLOAT)  AS "VENDOR_LEAD_TIME"

FROM       sales     s
LEFT JOIN  traffic   t ON  s."DATE" = t."DATE"
                       AND s."ASIN" = t."ASIN"
                       AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
                       AND s."PERIOD" = t."PERIOD"
LEFT JOIN  inv       i ON  s."DATE" = i."DATE"
                       AND s."ASIN" = i."ASIN"
                       AND s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT JOIN  receipts  r ON  s."DATE" = r."DATE"

ORDER BY    s."DATE",
            s."ASIN";