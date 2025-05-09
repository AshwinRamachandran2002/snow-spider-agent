/*  Daily manufacturing‑view sales report – 30 days prior to 6‑Feb‑2022  */
WITH
/*--------------------------------------------------------------------*/
/* 1.  SALES (ordered + shipped)                                       */
sales AS (
    SELECT
        CAST("DATE" AS DATE)                  AS "DATE",
        "ASIN",
        "ORDERED_UNITS",
        "ORDERED_REVENUE",
        "SHIPPED_UNITS",
        "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "PERIOD"          = 'DAILY'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW"= 'Manufacturing'
      AND CAST("DATE" AS DATE) BETWEEN '2022-01-08' AND '2022-02-06'
),
/*--------------------------------------------------------------------*/
/* 2.  TRAFFIC (glance views)                                          */
traffic AS (
    SELECT
        CAST("DATE" AS DATE)                  AS "DATE",
        "ASIN",
        "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE "PERIOD"          = 'DAILY'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW"= 'Manufacturing'
      AND CAST("DATE" AS DATE) BETWEEN '2022-01-08' AND '2022-02-06'
),
/*--------------------------------------------------------------------*/
/* 3.  INVENTORY                                                      */
inv AS (
    SELECT
        CAST("DATE" AS DATE)                         AS "DATE",
        "ASIN",
        "PROCURABLE_PRODUCT_OOS",
        "SELLABLE_ON_HAND_UNITS",
        "UNSELLABLE_ON_HAND_UNITS",
        "SELLABLE_ON_HAND_INVENTORY",
        "UNSELLABLE_ON_HAND_INVENTORY",
        "NET_RECEIVED_UNITS",
        "NET_RECEIVED",
        "OPEN_PURCHASE_ORDER_QUANTITY",
        "UNFILLED_CUSTOMER_ORDERED_UNITS",
        "VENDOR_CONFIRMATION_RATE",
        "RECEIVE_FILL_RATE",
        "SELL_THROUGH_RATE",
        "OVERALL_VENDOR_LEAD_TIME_DAYS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE "PERIOD"          = 'DAILY'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW"= 'Manufacturing'
      AND CAST("DATE" AS DATE) BETWEEN '2022-01-08' AND '2022-02-06'
),
/*--------------------------------------------------------------------*/
/* 4.  NET‑PPM                                                        */
ppm AS (
    SELECT
        CAST("DATE" AS DATE)                  AS "DATE",
        "ASIN",
        "NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"
    WHERE "PERIOD"          = 'DAILY'
      AND "PROGRAM"         = 'Amazon Retail'
      AND "DISTRIBUTOR_VIEW"= 'Manufacturing'
      AND CAST("DATE" AS DATE) BETWEEN '2022-01-08' AND '2022-02-06'
)
/*--------------------------------------------------------------------*/
SELECT
    s."DATE"                                                AS "REPORT_DATE",
    s."ASIN",

    /* -----------  Sales KPIs -------------------------------------- */
    s."ORDERED_UNITS"                                       AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE"                                     AS "ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" <> 0
         THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
         ELSE NULL END                                      AS "AVG_SELLING_PRICE",

    /* -----------  Traffic / Conversion --------------------------- */
    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" <> 0
         THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
         ELSE NULL END                                      AS "CONVERSION_RATE",

    /* -----------  Shipment --------------------------------------- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* -----------  Profitability ---------------------------------- */
    p."NET_PPM"                                             AS "AVG_NET_PPM",

    /* -----------  Inventory (daily values) ----------------------- */
    i."PROCURABLE_PRODUCT_OOS"                              AS "AVG_PROCURABLE_PRODUCT_OOS",
    /* on‑hand units & value */
    (i."SELLABLE_ON_HAND_UNITS"   + i."UNSELLABLE_ON_HAND_UNITS")      AS "TOTAL_ON_HAND_UNITS",
    (i."SELLABLE_ON_HAND_INVENTORY"+ i."UNSELLABLE_ON_HAND_INVENTORY") AS "TOTAL_ON_HAND_VALUE",
    /* Receiving & PO */
    i."NET_RECEIVED_UNITS"                                  AS "NET_RECEIVED_UNITS",
    i."NET_RECEIVED"                                        AS "NET_RECEIVED_VALUE",
    i."OPEN_PURCHASE_ORDER_QUANTITY"                        AS "OPEN_PO_QUANTITY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS"                     AS "UNFILLED_CUSTOMER_ORDERED_UNITS",

    /* -----------  Operational rates ------------------------------ */
    i."VENDOR_CONFIRMATION_RATE"                            AS "VENDOR_CONFIRMATION_RATE",
    i."RECEIVE_FILL_RATE"                                   AS "RECEIVE_FILL_RATE",
    i."SELL_THROUGH_RATE"                                   AS "SELL_THROUGH_RATE",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS"                       AS "VENDOR_LEAD_TIME_DAYS"

FROM        sales      s
LEFT JOIN   traffic    t  USING ("DATE","ASIN")
LEFT JOIN   inv        i  USING ("DATE","ASIN")
LEFT JOIN   ppm        p  USING ("DATE","ASIN")
ORDER BY    s."DATE" ASC,
            s."ASIN";