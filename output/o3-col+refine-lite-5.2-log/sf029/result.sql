/*  Daily sales‑traffic‑inventory‑margin report   
    Window : 8‑Jan‑2022  →  6‑Feb‑2022 (30 days – inclusive)  
    Scope  : Amazon Retail – Manufacturing distributor view (period = DAILY)
*/
SELECT
    s."DATE",
    s."ASIN",

    /* --------  Sales  -------- */
    s."ORDERED_UNITS",
    s."ORDERED_REVENUE",
    (s."ORDERED_REVENUE" / NULLIF(s."ORDERED_UNITS",0))                    AS "AVG_SELL_PRICE",

    /* --------  Traffic  -------- */
    t."GLANCE_VIEWS",
    (s."ORDERED_UNITS" / NULLIF(t."GLANCE_VIEWS",0))                       AS "CONVERSION_RATE",

    /* --------  Shipments  -------- */
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* --------  Profitability  -------- */
    n."NET_PPM",

    /* --------  Inventory  -------- */
    i."PROCURABLE_PRODUCT_OOS",
    (i."SELLABLE_ON_HAND_UNITS"   + i."UNSELLABLE_ON_HAND_UNITS")          AS "TOTAL_ON_HAND_UNITS",
    (i."SELLABLE_ON_HAND_INVENTORY" + i."UNSELLABLE_ON_HAND_INVENTORY")    AS "TOTAL_ON_HAND_VALUE",
    i."NET_RECEIVED_UNITS",
    i."NET_RECEIVED"                                                      AS "NET_RECEIVED_VALUE",
    i."OPEN_PURCHASE_ORDER_QUANTITY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",

    /* --------  Operational KPI  -------- */
    i."VENDOR_CONFIRMATION_RATE",
    i."RECEIVE_FILL_RATE",
    i."SELL_THROUGH_RATE",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS"                                      AS "VENDOR_LEAD_TIME_DAYS"

FROM  AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"      AS s

/* traffic */
LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC" AS t
       ON  s."DATE" = t."DATE"
       AND s."ASIN" = t."ASIN"
       AND t."PERIOD"           = 'DAILY'
       AND t."PROGRAM"          = 'Amazon Retail'
       AND t."DISTRIBUTOR_VIEW" = 'Manufacturing'

/* inventory */
LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY" AS i
       ON  s."DATE" = i."DATE"
       AND s."ASIN" = i."ASIN"
       AND i."PERIOD"           = 'DAILY'
       AND i."PROGRAM"          = 'Amazon Retail'
       AND i."DISTRIBUTOR_VIEW" = 'Manufacturing'

/* NET‑PPM */
LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"   AS n
       ON  s."DATE" = n."DATE"
       AND s."ASIN" = n."ASIN"
       AND n."PERIOD"           = 'DAILY'
       AND n."PROGRAM"          = 'Amazon Retail'
       AND n."DISTRIBUTOR_VIEW" = 'Manufacturing'

/* primary filter on sales table */
WHERE s."PERIOD"           = 'DAILY'
  AND s."PROGRAM"          = 'Amazon Retail'
  AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'

ORDER BY
    s."DATE",
    s."ASIN";