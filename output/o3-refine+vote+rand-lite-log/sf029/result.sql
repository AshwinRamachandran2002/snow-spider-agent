SELECT
    s."DATE",
    s."ASIN",
    s."PRODUCT_TITLE",

    /* -------------  Sales metrics ---------------- */
    s."ORDERED_UNITS"                            AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE"                          AS "TOTAL_ORDERED_REVENUE",
    CASE WHEN s."ORDERED_UNITS" <> 0
         THEN s."ORDERED_REVENUE" / s."ORDERED_UNITS"
    END                                          AS "AVG_SELLING_PRICE",
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",

    /* -------------  Traffic metrics -------------- */
    t."GLANCE_VIEWS",
    CASE WHEN t."GLANCE_VIEWS" <> 0
         THEN s."ORDERED_UNITS" / t."GLANCE_VIEWS"
    END                                          AS "CONVERSION_RATE",

    /* -------------  Profitability --------------- */
    n."NET_PPM"                                  AS "AVG_NET_PPM",

    /* -------------  Inventory metrics ----------- */
    i."PROCURABLE_PRODUCT_OOS"                   AS "AVG_PROCURABLE_PRODUCT_OOS",
    i."SELLABLE_ON_HAND_UNITS"                   AS "TOTAL_ON_HAND_UNITS",
    i."SELLABLE_ON_HAND_INVENTORY"               AS "TOTAL_ON_HAND_INVENTORY_VALUE",
    i."NET_RECEIVED_UNITS"                       AS "NET_RECEIVED_UNITS",
    i."NET_RECEIVED"                             AS "NET_RECEIVED_VALUE",
    i."OPEN_PURCHASE_ORDER_QUANTITY",
    i."UNFILLED_CUSTOMER_ORDERED_UNITS",

    /* -------------  Operational KPIs ------------ */
    i."VENDOR_CONFIRMATION_RATE"                 AS "AVG_VENDOR_CONFIRMATION_RATE",
    i."RECEIVE_FILL_RATE"                        AS "AVG_RECEIVE_FILL_RATE",
    i."SELL_THROUGH_RATE"                        AS "AVG_SELL_THROUGH_RATE",
    i."OVERALL_VENDOR_LEAD_TIME_DAYS"            AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"          s
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"   t
       ON t."DATE"              = s."DATE"
      AND t."ASIN"              = s."ASIN"
      AND t."PROGRAM"           = s."PROGRAM"
      AND t."PERIOD"            = s."PERIOD"
      AND t."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
       ON i."DATE"              = s."DATE"
      AND i."ASIN"              = s."ASIN"
      AND i."PROGRAM"           = s."PROGRAM"
      AND i."PERIOD"            = s."PERIOD"
      AND i."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM"   n
       ON n."DATE"              = s."DATE"
      AND n."ASIN"              = s."ASIN"
      AND n."PROGRAM"           = s."PROGRAM"
      AND n."PERIOD"            = s."PERIOD"
      AND n."DISTRIBUTOR_VIEW"  = s."DISTRIBUTOR_VIEW"

WHERE s."PERIOD"           = 'DAILY'
  AND s."PROGRAM"          = 'Amazon Retail'
  AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND s."DATE" BETWEEN '2022-01-08'::TIMESTAMP_LTZ
                   AND '2022-02-06'::TIMESTAMP_LTZ

ORDER BY s."DATE", s."ASIN";