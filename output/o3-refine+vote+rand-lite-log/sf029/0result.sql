WITH sales_daily AS (
    SELECT 
        "DATE"::DATE                                                       AS "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        MAX("PRODUCT_TITLE")                                               AS "PRODUCT_TITLE",
        SUM("ORDERED_UNITS")                                               AS "ORDERED_UNITS",
        SUM("ORDERED_REVENUE")                                             AS "ORDERED_REVENUE",
        SUM("SHIPPED_UNITS")                                               AS "SHIPPED_UNITS",
        SUM("SHIPPED_REVENUE")                                             AS "SHIPPED_REVENUE"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE   "PERIOD" = 'DAILY'
        AND "PROGRAM" = 'Amazon Retail'
        AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2,3,4,5
),

traffic_daily AS (
    SELECT 
        "DATE"::DATE                                   AS "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        SUM("GLANCE_VIEWS")                            AS "GLANCE_VIEWS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE   "PERIOD" = 'DAILY'
        AND "PROGRAM" = 'Amazon Retail'
        AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2,3,4,5
),

inventory_daily AS (
    SELECT
        "DATE"::DATE                                   AS "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        AVG("PROCURABLE_PRODUCT_OOS")                  AS "AVG_PROCURABLE_PRODUCT_OOS",
        AVG("VENDOR_CONFIRMATION_RATE")                AS "AVG_VENDOR_CONFIRMATION_RATE",
        AVG("RECEIVE_FILL_RATE")                       AS "AVG_RECEIVE_FILL_RATE",
        AVG("SELL_THROUGH_RATE")                       AS "AVG_SELL_THROUGH_RATE",
        AVG("OVERALL_VENDOR_LEAD_TIME_DAYS")           AS "AVG_VENDOR_LEAD_TIME",
        SUM("SELLABLE_ON_HAND_UNITS")                  AS "SELLABLE_ON_HAND_UNITS",
        SUM("UNSELLABLE_ON_HAND_UNITS")                AS "UNSELLABLE_ON_HAND_UNITS",
        SUM("SELLABLE_ON_HAND_INVENTORY")              AS "SELLABLE_ON_HAND_INVENTORY",
        SUM("UNSELLABLE_ON_HAND_INVENTORY")            AS "UNSELLABLE_ON_HAND_INVENTORY",
        SUM("NET_RECEIVED_UNITS")                      AS "NET_RECEIVED_UNITS",
        SUM("NET_RECEIVED")                            AS "NET_RECEIVED_VALUE",
        SUM("OPEN_PURCHASE_ORDER_QUANTITY")            AS "OPEN_PURCHASE_ORDER_QUANTITY",
        SUM("UNFILLED_CUSTOMER_ORDERED_UNITS")         AS "UNFILLED_CUSTOMER_ORDERED_UNITS"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE   "PERIOD" = 'DAILY'
        AND "PROGRAM" = 'Amazon Retail'
        AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2,3,4,5
),

netppm_daily AS (
    SELECT
        "DATE"::DATE               AS "DATE",
        "ASIN",
        "PROGRAM",
        "PERIOD",
        "DISTRIBUTOR_VIEW",
        AVG("NET_PPM")             AS "AVG_NET_PPM"
    FROM AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_NET_PPM"
    WHERE   "PERIOD" = 'DAILY'
        AND "PROGRAM" = 'Amazon Retail'
        AND "DISTRIBUTOR_VIEW" = 'Manufacturing'
        AND "DATE" BETWEEN '2022-01-08' AND '2022-02-06'
    GROUP BY 1,2,3,4,5
)

SELECT
    s."DATE",
    s."ASIN",
    s."PRODUCT_TITLE",
    s."ORDERED_UNITS"                                              AS "TOTAL_ORDERED_UNITS",
    s."ORDERED_REVENUE",
    CASE 
        WHEN s."ORDERED_UNITS" <> 0 
        THEN ROUND(s."ORDERED_REVENUE" / s."ORDERED_UNITS", 4) 
    END                                                            AS "AVG_SELLING_PRICE",
    t."GLANCE_VIEWS",
    CASE 
        WHEN t."GLANCE_VIEWS" <> 0 
        THEN ROUND(s."ORDERED_UNITS" / t."GLANCE_VIEWS", 4) 
    END                                                            AS "CONVERSION_RATE",
    s."SHIPPED_UNITS",
    s."SHIPPED_REVENUE",
    np."AVG_NET_PPM",
    inv."AVG_PROCURABLE_PRODUCT_OOS",
    (inv."SELLABLE_ON_HAND_UNITS"  + inv."UNSELLABLE_ON_HAND_UNITS")      AS "TOTAL_ON_HAND_UNITS",
    (inv."SELLABLE_ON_HAND_INVENTORY" + inv."UNSELLABLE_ON_HAND_INVENTORY")AS "TOTAL_ON_HAND_VALUE",
    inv."NET_RECEIVED_UNITS",
    inv."NET_RECEIVED_VALUE",
    inv."OPEN_PURCHASE_ORDER_QUANTITY",
    inv."UNFILLED_CUSTOMER_ORDERED_UNITS",
    inv."AVG_VENDOR_CONFIRMATION_RATE",
    inv."AVG_RECEIVE_FILL_RATE",
    inv."AVG_SELL_THROUGH_RATE",
    inv."AVG_VENDOR_LEAD_TIME"
FROM sales_daily            s
LEFT JOIN traffic_daily     t   ON  t."DATE" = s."DATE" 
                               AND t."ASIN" = s."ASIN"
LEFT JOIN inventory_daily   inv ON  inv."DATE" = s."DATE" 
                               AND inv."ASIN" = s."ASIN"
LEFT JOIN netppm_daily      np  ON  np."DATE" = s."DATE" 
                               AND np."ASIN" = s."ASIN"
ORDER BY s."DATE" ASC, s."ASIN";