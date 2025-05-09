/*  Daily product-level report – Manufacturing view – 2022-01-07 → 2022-02-05  */
WITH
/* ---------------------------------------------------------------------------
   1.  Sales facts
--------------------------------------------------------------------------- */
SALES AS (
    SELECT
        CAST("DATE" AS DATE)                            AS "DATE",
        "ASIN",
        SUM("ORDERED_UNITS")                            AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                          AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")                            AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                          AS "SHIPPED_REVENUE",
        SUM("SHIPPED_COGS")                             AS "SHIPPED_COGS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/* ---------------------------------------------------------------------------
   2.  Traffic (glance views)
--------------------------------------------------------------------------- */
TRAFFIC AS (
    SELECT
        CAST("DATE" AS DATE)               AS "DATE",
        "ASIN",
        SUM("GLANCE_VIEWS")                AS "GLANCE_VIEWS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/* ---------------------------------------------------------------------------
   3.  Inventory (on-hand & OOS flag)
--------------------------------------------------------------------------- */
INVENTORY AS (
    SELECT
        CAST("DATE" AS DATE)                                                                  AS "DATE",
        "ASIN",
        SUM( COALESCE("SELLABLE_ON_HAND_UNITS",0) + COALESCE("UNSELLABLE_ON_HAND_UNITS",0) )  AS "ON_HAND_UNITS",
        SUM( COALESCE("SELLABLE_ON_HAND_INVENTORY",0) + COALESCE("UNSELLABLE_ON_HAND_INVENTORY",0) ) AS "ON_HAND_VALUE",
        AVG( CASE WHEN COALESCE("SELLABLE_ON_HAND_UNITS",0) = 0 THEN 1 ELSE 0 END )           AS "AVG_PROCURABLE_OOS"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY CAST("DATE" AS DATE), "ASIN"
),

/* ---------------------------------------------------------------------------
   4.  Net receipts (date level, no ASIN granularity)
--------------------------------------------------------------------------- */
RECEIPTS AS (
    SELECT
        CAST("RECEIVE_DATE" AS DATE)        AS "DATE",
        SUM("QUANTITY")                     AS "NET_RECEIPT_UNITS",
        SUM("NET_RECEIPTS")                 AS "NET_RECEIPT_VALUE"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE "RECEIVE_DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY CAST("RECEIVE_DATE" AS DATE)
),

/* ---------------------------------------------------------------------------
   5.  Vendor lead-time  (days between order & ship)
--------------------------------------------------------------------------- */
VENDOR_LT AS (
    SELECT
        CAST("ORDER_DATE" AS DATE)                                       AS "DATE",
        AVG( DATEDIFF('day', "ORDER_DATE", "SHIP_DATE") )                AS "AVG_VENDOR_LEAD_TIME"
    FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."PAYMENTS_CUSTOMER_SHIPMENT_DETAILS"
    WHERE "ORDER_DATE" BETWEEN '2022-01-07' AND '2022-02-05'
    GROUP BY CAST("ORDER_DATE" AS DATE)
)

/* ---------------------------------------------------------------------------
   6.  Final daily product report
--------------------------------------------------------------------------- */
SELECT
    S."DATE",
    S."ASIN",

    /* ----- Sales & traffic KPIs ----------------------------------------- */
    S."ORDERED_UNITS",
    S."ORDERED_REVENUE",
    CASE WHEN S."ORDERED_UNITS" > 0
         THEN S."ORDERED_REVENUE" / S."ORDERED_UNITS"
    END                                            AS "AVG_SELLING_PRICE",

    T."GLANCE_VIEWS",
    CASE WHEN T."GLANCE_VIEWS" > 0
         THEN S."ORDERED_UNITS" / T."GLANCE_VIEWS"
    END                                            AS "CONVERSION_RATE",

    S."SHIPPED_UNITS",
    S."SHIPPED_REVENUE",

    /* Net PPM (profit per unit) */
    CASE WHEN S."SHIPPED_UNITS" > 0
         THEN (S."SHIPPED_REVENUE" - S."SHIPPED_COGS") / S."SHIPPED_UNITS"
    END                                            AS "AVG_NET_PPM",

    /* ----- Inventory ----------------------------------------------------- */
    I."AVG_PROCURABLE_OOS"                        AS "AVG_PROCURABLE_PRODUCT_OOS",
    I."ON_HAND_UNITS",
    I."ON_HAND_VALUE",

    /* ----- Receipts / replenishment -------------------------------------- */
    R."NET_RECEIPT_UNITS",
    R."NET_RECEIPT_VALUE",

    /* Placeholder for open POs (no source table in sample) */
    NULL :: FLOAT                                 AS "OPEN_PO_QUANTITY",

    /* Unfilled customer demand */
    (S."ORDERED_UNITS" - S."SHIPPED_UNITS")       AS "UNFILLED_CUSTOMER_ORDERED_UNITS",

    /* Vendor / receive performance */
    CASE WHEN S."ORDERED_UNITS" > 0
         THEN S."SHIPPED_UNITS" / S."ORDERED_UNITS"
    END                                            AS "VENDOR_CONFIRMATION_RATE",

    CASE WHEN S."ORDERED_UNITS" > 0
         THEN S."SHIPPED_UNITS" / S."ORDERED_UNITS"
    END                                            AS "RECEIVE_FILL_RATE",

    CASE WHEN I."ON_HAND_UNITS" > 0
         THEN S."SHIPPED_UNITS" / I."ON_HAND_UNITS"
    END                                            AS "SELL_THROUGH_RATE",

    V."AVG_VENDOR_LEAD_TIME"                      AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM SALES        S
LEFT JOIN TRAFFIC  T ON S."DATE" = T."DATE"  AND S."ASIN" = T."ASIN"
LEFT JOIN INVENTORY I ON S."DATE" = I."DATE" AND S."ASIN" = I."ASIN"
LEFT JOIN RECEIPTS  R ON S."DATE" = R."DATE"
LEFT JOIN VENDOR_LT V ON S."DATE" = V."DATE"
ORDER BY S."DATE", S."ASIN";