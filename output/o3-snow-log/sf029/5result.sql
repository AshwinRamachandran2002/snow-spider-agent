/* ============================================================================
   Daily detailed sales report – Manufacturing program
   Window : 2022-01-08 … 2022-02-06  (30 days preceding 06-Feb-2022 inclusive)
   Grain  : 1 row per Day × ASIN × Distributor_View
============================================================================ */
WITH
/* 1.  Sales facts ----------------------------------------------------------- */
sales AS (
    SELECT
        "DATE",
        "ASIN",
        "DISTRIBUTOR_VIEW",
        /* totals per ASIN-day */
        SUM("ORDERED_UNITS")   AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE") AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")   AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE") AS "SHIPPED_REVENUE",
        SUM("SHIPPED_COGS")    AS "SHIPPED_COGS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","DISTRIBUTOR_VIEW"
),

/* 2.  Traffic (glance views) ----------------------------------------------- */
traffic AS (
    SELECT
        "DATE",
        "ASIN",
        "DISTRIBUTOR_VIEW",
        SUM("GLANCE_VIEWS") AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","DISTRIBUTOR_VIEW"
),

/* 3.  Inventory positions --------------------------------------------------- */
inventory AS (
    SELECT
        "DATE",
        "ASIN",
        "DISTRIBUTOR_VIEW",
        /* total on-hand units & value (sellable + unsellable) */
        SUM("SELLABLE_ON_HAND_UNITS"  + "UNSELLABLE_ON_HAND_UNITS")     AS "TOTAL_ON_HAND_UNITS",
        SUM("SELLABLE_ON_HAND_INVENTORY" + "UNSELLABLE_ON_HAND_INVENTORY")
                                                                       AS "TOTAL_ON_HAND_VALUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "DATE","ASIN","DISTRIBUTOR_VIEW"
),

/* 4.  Distributor receipts (net received units / value) -------------------- */
receipts AS (
    SELECT
        "RECEIVE_DATE"                              AS "DATE",
        SUM("QUANTITY")     AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIPTS") AS "NET_RECEIVED_VALUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE "RECEIVE_DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY "RECEIVE_DATE"
)

/* 5.  Assemble the final report -------------------------------------------- */
SELECT
    s."DATE",
    s."ASIN",
    /* ----- Demand metrics ----- */
    s."ORDERED_UNITS",
    s."ORDERED_REVENUE",
    CASE
        WHEN s."ORDERED_UNITS" = 0 THEN NULL
        ELSE ROUND(s."ORDERED_REVENUE"::FLOAT / s."ORDERED_UNITS", 4)
    END                              AS "AVG_SELLING_PRICE",
    t."GLANCE_VIEWS",
    CASE
        WHEN t."GLANCE_VIEWS" IS NULL OR t."GLANCE_VIEWS" = 0 THEN NULL
        ELSE ROUND(s."ORDERED_UNITS"::FLOAT / t."GLANCE_VIEWS", 4)
    END                              AS "CONVERSION_RATE",

    /* ----- Shipments & profitability ----- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",
    CASE
        WHEN s."SHIPPED_UNITS" = 0 THEN NULL
        ELSE ROUND((s."SHIPPED_REVENUE" - s."SHIPPED_COGS") / s."SHIPPED_UNITS", 4)
    END                              AS "AVG_NET_PPM",

    /* ----- Inventory & receipts ------------------------------------------- */
    NULL::FLOAT                      AS "AVG_PROCURABLE_PRODUCT_OOS",
    i."TOTAL_ON_HAND_UNITS",
    i."TOTAL_ON_HAND_VALUE",
    r."NET_RECEIVED_UNITS",
    r."NET_RECEIVED_VALUE",

    /* ----- Additional supply-chain KPIs (place-holders) -------------------- */
    NULL::FLOAT                      AS "OPEN_PURCHASE_ORDER_QTY",
    NULL::FLOAT                      AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
    NULL::FLOAT                      AS "AVG_VENDOR_CONFIRMATION_RATE",
    NULL::FLOAT                      AS "RECEIVE_FILL_RATE",
    NULL::FLOAT                      AS "SELL_THROUGH_RATE",
    NULL::FLOAT                      AS "VENDOR_LEAD_TIME"

FROM           sales     s
LEFT  JOIN     traffic   t ON t."DATE" = s."DATE"
                           AND t."ASIN" = s."ASIN"
                           AND t."DISTRIBUTOR_VIEW" = s."DISTRIBUTOR_VIEW"
LEFT  JOIN     inventory i ON i."DATE" = s."DATE"
                           AND i."ASIN" = s."ASIN"
                           AND i."DISTRIBUTOR_VIEW" = s."DISTRIBUTOR_VIEW"
LEFT  JOIN     receipts  r ON r."DATE" = s."DATE"

ORDER BY s."DATE" DESC NULLS LAST,
         s."ASIN";