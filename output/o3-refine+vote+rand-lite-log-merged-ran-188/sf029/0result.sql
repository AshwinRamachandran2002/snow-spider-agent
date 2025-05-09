SELECT
    s."DATE",
    s."ASIN",

    /* ---------- Sales ---------- */
    SUM(s."ORDERED_UNITS")                                            AS "TOTAL_ORDERED_UNITS",
    SUM(s."ORDERED_REVENUE")                                          AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN SUM(s."ORDERED_UNITS") > 0
         THEN SUM(s."ORDERED_REVENUE") / SUM(s."ORDERED_UNITS")
    END                                                               AS "AVG_SELLING_PRICE",

    /* ---------- Traffic ---------- */
    SUM(t."GLANCE_VIEWS")                                             AS "GLANCE_VIEWS",
    CASE WHEN SUM(t."GLANCE_VIEWS") > 0
         THEN SUM(s."ORDERED_UNITS") / SUM(t."GLANCE_VIEWS")
    END                                                               AS "CONVERSION_RATE",

    /* ---------- Shipments ---------- */
    SUM(s."SHIPPED_UNITS")                                            AS "SHIPPED_UNITS",
    SUM(s."SHIPPED_REVENUE")                                          AS "SHIPPED_REVENUE",

    /* ---------- Margin (NET-PPM) ---------- */
    AVG(n."NET_PPM")                                                  AS "AVG_NET_PPM",

    /* ---------- Inventory ---------- */
    AVG(i."PROCURABLE_PRODUCT_OOS")                                   AS "AVG_PROCURABLE_PRODUCT_OOS",
    SUM(i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")    AS "TOTAL_ON_HAND_UNITS",
    NULL::FLOAT                                                       AS "TOTAL_ON_HAND_VALUE",   -- cost data not available
    SUM(i."NET_RECEIVED_UNITS")                                       AS "NET_RECEIVED_UNITS",
    NULL::FLOAT                                                       AS "NET_RECEIVED_VALUE",    -- cost data not available
    SUM(i."OPEN_PURCHASE_ORDER_QUANTITY")                             AS "OPEN_PO_QUANTITY",
    SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS")                          AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
    AVG(i."VENDOR_CONFIRMATION_RATE")                                 AS "AVG_VENDOR_CONFIRMATION_RATE",
    AVG(i."RECEIVE_FILL_RATE")                                        AS "AVG_RECEIVE_FILL_RATE",
    AVG(i."SELL_THROUGH_RATE")                                        AS "AVG_SELL_THROUGH_RATE",
    AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS")                            AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM   "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"        s
LEFT   JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC" t
       ON  s."DATE"             = t."DATE"
       AND s."ASIN"             = t."ASIN"
       AND s."PROGRAM"          = t."PROGRAM"
       AND s."PERIOD"           = t."PERIOD"
       AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
LEFT   JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
       ON  s."DATE"             = i."DATE"
       AND s."ASIN"             = i."ASIN"
       AND s."PROGRAM"          = i."PROGRAM"
       AND s."PERIOD"           = i."PERIOD"
       AND s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT   JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM" n
       ON  s."DATE"             = n."DATE"
       AND s."ASIN"             = n."ASIN"
       AND s."PROGRAM"          = n."PROGRAM"
       AND s."PERIOD"           = n."PERIOD"
       AND s."DISTRIBUTOR_VIEW" = n."DISTRIBUTOR_VIEW"

WHERE  s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND  s."PERIOD"           = 'DAILY'
  AND  s."PROGRAM"          = 'Amazon Retail'
  AND  s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'

GROUP BY
    s."DATE",
    s."ASIN"

ORDER BY
    s."DATE",
    s."ASIN";