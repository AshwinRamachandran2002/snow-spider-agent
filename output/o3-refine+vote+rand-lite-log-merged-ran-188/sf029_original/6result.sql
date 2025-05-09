/*  Daily manufacturing‑view product report   
    30‑day window : 8‑Jan‑2022  →  6‑Feb‑2022   */

SELECT
    s."DATE",
    s."ASIN",
    s."PRODUCT_TITLE",

    /*  ─────────  Sales  ───────── */
    SUM(s."ORDERED_UNITS")                                                        AS "TOTAL_ORDERED_UNITS",
    SUM(s."ORDERED_REVENUE")                                                      AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN SUM(s."ORDERED_UNITS") = 0 THEN NULL
         ELSE ROUND(SUM(s."ORDERED_REVENUE")/SUM(s."ORDERED_UNITS"),4) END        AS "AVG_SELLING_PRICE",

    /*  ─────────  Traffic  ──────── */
    SUM(t."GLANCE_VIEWS")                                                         AS "GLANCE_VIEWS",
    CASE WHEN SUM(t."GLANCE_VIEWS") = 0 THEN NULL
         ELSE ROUND(SUM(s."ORDERED_UNITS")/SUM(t."GLANCE_VIEWS"),4) END           AS "CONVERSION_RATE",

    /*  ─────────  Shipments  ────── */
    SUM(s."SHIPPED_UNITS")                                                        AS "SHIPPED_UNITS",
    SUM(s."SHIPPED_REVENUE")                                                      AS "SHIPPED_REVENUE",

    /*  ─────────  Profitability  ── */
    ROUND(AVG(n."NET_PPM"),4)                                                     AS "AVG_NET_PPM",

    /*  ─────────  Inventory  ────── */
    ROUND(AVG(i."PROCURABLE_PRODUCT_OOS"),4)                                      AS "AVG_PROCURABLE_PRODUCT_OOS",
    SUM(i."SELLABLE_ON_HAND_UNITS") + SUM(i."UNSELLABLE_ON_HAND_UNITS")           AS "TOTAL_ONHAND_UNITS",
    SUM(i."SELLABLE_ON_HAND_INVENTORY") + SUM(i."UNSELLABLE_ON_HAND_INVENTORY")   AS "TOTAL_ONHAND_VALUE",
    SUM(i."NET_RECEIVED_UNITS")                                                   AS "NET_RECEIVED_UNITS",
    SUM(i."NET_RECEIVED")                                                         AS "NET_RECEIVED_VALUE",
    SUM(i."OPEN_PURCHASE_ORDER_QUANTITY")                                         AS "OPEN_PO_QUANTITY",
    SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS")                                      AS "UNFILLED_CUSTOMER_ORDERED_UNITS",

    /*  ── Inventory performance averages ── */
    ROUND(AVG(i."VENDOR_CONFIRMATION_RATE"),4)                                    AS "AVG_VENDOR_CONFIRMATION_RATE",
    ROUND(AVG(i."RECEIVE_FILL_RATE"),4)                                           AS "AVG_RECEIVE_FILL_RATE",
    ROUND(AVG(i."SELL_THROUGH_RATE"),4)                                           AS "AVG_SELL_THROUGH_RATE",
    ROUND(AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS"),4)                               AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM  AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_SALES         s
LEFT  JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_TRAFFIC   t
       ON  t."DATE"              = s."DATE"
       AND t."ASIN"              = s."ASIN"
       AND t."PROGRAM"           = s."PROGRAM"
       AND t."PERIOD"            = s."PERIOD"
       AND t."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT  JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_INVENTORY i
       ON  i."DATE"              = s."DATE"
       AND i."ASIN"              = s."ASIN"
       AND i."PROGRAM"           = s."PROGRAM"
       AND i."PERIOD"            = s."PERIOD"
       AND i."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT  JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_NET_PPM   n
       ON  n."DATE"              = s."DATE"
       AND n."ASIN"              = s."ASIN"
       AND n."PROGRAM"           = s."PROGRAM"
       AND n."PERIOD"            = s."PERIOD"
       AND n."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"

WHERE s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'            -- 30 days up to 6‑Feb‑2022
  AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND s."PERIOD"           = 'DAILY'
  AND s."PROGRAM"          = 'Amazon Retail'

GROUP BY
    s."DATE",
    s."ASIN",
    s."PRODUCT_TITLE"

ORDER BY
    s."DATE",
    s."ASIN";