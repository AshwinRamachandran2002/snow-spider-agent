/* Daily detailed sales report – Manufacturing view – 30-day window prior to 06-Feb-2022 */
SELECT
        s."DATE"                                                          AS "DATE",
        s."ASIN"                                                          AS "ASIN",

        /* --- Demand / Commerce --- */
        s."ORDERED_UNITS"                                                 AS "ORDERED_UNITS",
        s."ORDERED_REVENUE"                                               AS "ORDERED_REVENUE",
        /* average selling price based on shipped units                     */
        (s."SHIPPED_REVENUE" / NULLIF(s."SHIPPED_UNITS",0))               AS "AVG_SELL_PRICE",
        s."SHIPPED_UNITS"                                                 AS "SHIPPED_UNITS",
        s."SHIPPED_REVENUE"                                               AS "SHIPPED_REVENUE",

        /* --- Visibility / Traffic --- */
        t."GLANCE_VIEWS"                                                  AS "GLANCE_VIEWS",
        (s."SHIPPED_UNITS" / NULLIF(t."GLANCE_VIEWS",0))                  AS "CONVERSION_RATE",

        /* --- Profitability --- */
        np."NET_PPM"                                                      AS "AVG_NET_PPM",

        /* --- Supply-chain / Inventory --- */
        iv."PROCURABLE_PRODUCT_OOS"                                       AS "AVG_PROCURABLE_PRODUCT_OOS",
        (iv."SELLABLE_ON_HAND_UNITS" + iv."UNSELLABLE_ON_HAND_UNITS")     AS "TOTAL_ON_HAND_UNITS",
        /* on-hand value estimated with average sell price                  */
        ( iv."SELLABLE_ON_HAND_UNITS" + iv."UNSELLABLE_ON_HAND_UNITS")
             * (s."SHIPPED_REVENUE" / NULLIF(s."SHIPPED_UNITS",0))        AS "TOTAL_ON_HAND_VALUE",
        iv."NET_RECEIVED_UNITS"                                           AS "NET_RECEIVED_UNITS",
        iv."NET_RECEIVED"                                                 AS "NET_RECEIVED_VALUE",
        iv."OPEN_PURCHASE_ORDER_QUANTITY"                                 AS "OPEN_PO_QUANTITY",
        iv."UNFILLED_CUSTOMER_ORDERED_UNITS"                              AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
        iv."VENDOR_CONFIRMATION_RATE"                                     AS "AVG_VENDOR_CONFIRMATION_RATE",
        iv."RECEIVE_FILL_RATE"                                            AS "AVG_RECEIVE_FILL_RATE",
        iv."SELL_THROUGH_RATE"                                            AS "AVG_SELL_THROUGH_RATE",
        iv."OVERALL_VENDOR_LEAD_TIME_DAYS"                                AS "AVG_VENDOR_LEAD_TIME_DAYS"

FROM   AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"      s

/* traffic */
LEFT   JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC" t
       ON  s."DATE"             = t."DATE"
       AND s."ASIN"             = t."ASIN"
       AND s."PROGRAM"          = t."PROGRAM"
       AND s."PERIOD"           = t."PERIOD"
       AND t."DISTRIBUTOR_VIEW" = 'Manufacturing'

/* inventory */
LEFT   JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY" iv
       ON  s."DATE"             = iv."DATE"
       AND s."ASIN"             = iv."ASIN"
       AND s."PROGRAM"          = iv."PROGRAM"
       AND s."PERIOD"           = iv."PERIOD"
       AND iv."DISTRIBUTOR_VIEW"= 'Manufacturing'

/* net PPM */
LEFT   JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM" np
       ON  s."DATE"             = np."DATE"
       AND s."ASIN"             = np."ASIN"
       AND s."PROGRAM"          = np."PROGRAM"
       AND s."PERIOD"           = np."PERIOD"
       AND np."DISTRIBUTOR_VIEW"= 'Manufacturing'

/* --- scope filter --- */
WHERE  s."DISTRIBUTOR_VIEW" = 'Manufacturing'
  AND  s."PROGRAM"          = 'Amazon Retail'
  AND  s."PERIOD"           = 'DAILY'
  AND  s."DATE" BETWEEN '2022-01-08'::DATE AND '2022-02-06'::DATE

ORDER  BY s."DATE" ASC, s."ASIN" ASC;