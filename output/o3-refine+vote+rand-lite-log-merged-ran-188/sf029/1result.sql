SELECT
    s."DATE",
    s."ASIN",

    /* ----------  Sales KPIs  ---------- */
    SUM(s."ORDERED_UNITS")                                        AS "TOTAL_ORDERED_UNITS",
    SUM(s."ORDERED_REVENUE")                                      AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN SUM(s."ORDERED_UNITS") = 0 THEN NULL
         ELSE SUM(s."ORDERED_REVENUE") / SUM(s."ORDERED_UNITS")
    END                                                           AS "AVG_SELLING_PRICE",

    /* ----------  Traffic KPIs  ---------- */
    SUM(t."GLANCE_VIEWS")                                         AS "GLANCE_VIEWS",
    CASE WHEN SUM(t."GLANCE_VIEWS") = 0 THEN NULL
         ELSE SUM(s."SHIPPED_UNITS") / SUM(t."GLANCE_VIEWS")
    END                                                           AS "CONVERSION_RATE",

    /* ----------  Shipment KPIs  ---------- */
    SUM(s."SHIPPED_UNITS")                                        AS "SHIPPED_UNITS",
    SUM(s."SHIPPED_REVENUE")                                      AS "SHIPPED_REVENUE",

    /* ----------  Profitability  ---------- */
    AVG(p."NET_PPM")                                              AS "AVG_NET_PPM",

    /* ----------  Inventory KPIs  ---------- */
    AVG(i."PROCURABLE_PRODUCT_OOS")                               AS "AVG_PROCURABLE_PRODUCT_OOS",
    SUM(i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")          AS "TOTAL_ON_HAND_UNITS",
    -- estimate on-hand value at current ASP
    SUM(i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS") *
    CASE WHEN SUM(s."ORDERED_UNITS") = 0 THEN NULL
         ELSE SUM(s."ORDERED_REVENUE") / SUM(s."ORDERED_UNITS")
    END                                                           AS "ON_HAND_VALUE",
    SUM(i."NET_RECEIVED_UNITS")                                   AS "NET_RECEIVED_UNITS",
    SUM(i."NET_RECEIVED")                                         AS "NET_RECEIVED_VALUE",
    SUM(i."OPEN_PURCHASE_ORDER_QUANTITY")                         AS "OPEN_PO_QTY",
    SUM(i."UNFILLED_CUSTOMER_ORDERED_UNITS")                      AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
    AVG(i."VENDOR_CONFIRMATION_RATE")                             AS "AVG_VENDOR_CONFIRM_RATE",
    AVG(i."RECEIVE_FILL_RATE")                                    AS "AVG_RECEIVE_FILL_RATE",
    AVG(i."SELL_THROUGH_RATE")                                    AS "AVG_SELL_THROUGH_RATE",
    AVG(i."OVERALL_VENDOR_LEAD_TIME_DAYS")                        AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM  "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"      s
JOIN  "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"    t
      ON  s."DATE" = t."DATE"
      AND s."ASIN" = t."ASIN"
      AND s."PROGRAM" = t."PROGRAM"
      AND s."PERIOD" = t."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
JOIN  "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY"  i
      ON  s."DATE" = i."DATE"
      AND s."ASIN" = i."ASIN"
      AND s."PROGRAM" = i."PROGRAM"
      AND s."PERIOD" = i."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = i."DISTRIBUTOR_VIEW"
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM" p
      ON  s."DATE" = p."DATE"
      AND s."ASIN" = p."ASIN"
      AND s."PROGRAM" = p."PROGRAM"
      AND s."PERIOD" = p."PERIOD"
      AND s."DISTRIBUTOR_VIEW" = p."DISTRIBUTOR_VIEW"

WHERE s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND s."PROGRAM"         = 'Amazon Retail'
  AND s."PERIOD"          = 'DAILY'
  AND s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'   -- 30-day window up to 06-Feb-2022

GROUP BY
    s."DATE",
    s."ASIN"

ORDER BY
    s."DATE" ASC,
    s."ASIN" ASC;