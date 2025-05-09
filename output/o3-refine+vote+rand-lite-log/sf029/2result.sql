/*  Daily product‑level sales report – Manufacturing view
    30‑day window : 2022‑01‑08 → 2022‑02‑06 (inclusive)                                   */

SELECT
        s."DATE"                                                     AS "DATE"                       -- calendar day
      , s."ASIN"                                                     AS "ASIN"
      , s."PRODUCT_TITLE"                                            AS "PRODUCT_TITLE"

      /* -----------  Sales metrics ----------- */
      , s."ORDERED_UNITS"                                            AS "TOTAL_ORDERED_UNITS"
      , s."ORDERED_REVENUE"                                          AS "ORDERED_REVENUE"
      , CASE WHEN s."ORDERED_UNITS" = 0 
             THEN NULL 
             ELSE s."ORDERED_REVENUE"/s."ORDERED_UNITS" END         AS "AVG_SELLING_PRICE"

      /* -----------  Traffic metrics ----------- */
      , t."GLANCE_VIEWS"                                             AS "GLANCE_VIEWS"
      , CASE WHEN t."GLANCE_VIEWS" = 0 
             THEN NULL 
             ELSE s."ORDERED_UNITS"/t."GLANCE_VIEWS" END            AS "CONVERSION_RATE"

      /* -----------  Shipment metrics ----------- */
      , s."SHIPPED_UNITS"                                            AS "SHIPPED_UNITS"
      , s."SHIPPED_REVENUE"                                          AS "SHIPPED_REVENUE"

      /* -----------  Profitability / PPM ----------- */
      , n."NET_PPM"                                                  AS "AVG_NET_PPM"

      /* -----------  Inventory metrics ----------- */
      , i."PROCURABLE_PRODUCT_OOS"                                   AS "AVG_PROCURABLE_PRODUCT_OOS"
      , i."SELLABLE_ON_HAND_UNITS"                                   AS "TOTAL_ON_HAND_UNITS"
      , i."SELLABLE_ON_HAND_INVENTORY"                               AS "TOTAL_ON_HAND_INVENTORY_VALUE"
      , i."NET_RECEIVED_UNITS"                                       AS "NET_RECEIVED_UNITS"
      , i."NET_RECEIVED"                                             AS "NET_RECEIVED_VALUE"
      , i."OPEN_PURCHASE_ORDER_QUANTITY"                             AS "OPEN_PO_QUANTITY"
      , i."UNFILLED_CUSTOMER_ORDERED_UNITS"                          AS "UNFILLED_CUSTOMER_ORDERED_UNITS"

      /* -----------  Operational KPI averages ----------- */
      , i."VENDOR_CONFIRMATION_RATE"                                 AS "VENDOR_CONFIRMATION_RATE"
      , i."RECEIVE_FILL_RATE"                                        AS "RECEIVE_FILL_RATE"
      , i."SELL_THROUGH_RATE"                                        AS "SELL_THROUGH_RATE"
      , i."OVERALL_VENDOR_LEAD_TIME_DAYS"                            AS "VENDOR_LEAD_TIME_DAYS"

FROM    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"      AS s

/* -------------  Traffic ------------- */
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC"  AS t
       ON  t."DATE"             = s."DATE"
       AND t."ASIN"             = s."ASIN"
       AND t."PROGRAM"          = s."PROGRAM"
       AND t."PERIOD"           = s."PERIOD"
       AND t."DISTRIBUTOR_VIEW" = s."DISTRIBUTOR_VIEW"

/* -------------  Inventory ------------- */
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" AS i
       ON  i."DATE"             = s."DATE"
       AND i."ASIN"             = s."ASIN"
       AND i."PROGRAM"          = s."PROGRAM"
       AND i."PERIOD"           = s."PERIOD"
       AND i."DISTRIBUTOR_VIEW" = s."DISTRIBUTOR_VIEW"

/* -------------  Net PPM ------------- */
LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_NET_PPM"  AS n
       ON  n."DATE"             = s."DATE"
       AND n."ASIN"             = s."ASIN"
       AND n."PROGRAM"          = s."PROGRAM"
       AND n."PERIOD"           = s."PERIOD"
       AND n."DISTRIBUTOR_VIEW" = s."DISTRIBUTOR_VIEW"

WHERE   s."PERIOD"           = 'DAILY'
    AND s."PROGRAM"          = 'Amazon Retail'
    AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
    AND s."DATE" BETWEEN '2022-01-08' AND '2022-02-06'
ORDER BY s."DATE" ASC, s."ASIN";