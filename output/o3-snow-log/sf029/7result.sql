/*  Daily Manufacturing Sales + Traffic + Inventory + Net-PPM report  
    30-day window ending 06-Feb-2022 (07-Jan-2022 → 06-Feb-2022)  */

WITH sales_window AS (        --------------------  SALES
    SELECT  "DATE",
            "ASIN",
            "ORDERED_UNITS",
            "ORDERED_REVENUE",
            "SHIPPED_UNITS",
            "SHIPPED_REVENUE",
            CASE WHEN "ORDERED_UNITS" <> 0
                 THEN "ORDERED_REVENUE" / "ORDERED_UNITS"
            END                        AS "AVG_SELLING_PRICE"
    FROM  AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_SALES"
    WHERE "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND "DATE" BETWEEN '2022-01-07' AND '2022-02-06'
),

traffic_window AS (            --------------------  TRAFFIC
    SELECT  "DATE",
            "ASIN",
            "PERIOD",
            "GLANCE_VIEWS"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_TRAFFIC"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "DATE" BETWEEN '2022-01-07' AND '2022-02-06'
),

inventory_window AS (          --------------------  INVENTORY
    SELECT  "DATE",
            "ASIN",
            "SELLABLE_ON_HAND_UNITS",
            "UNSELLABLE_ON_HAND_UNITS",
            "SELLABLE_ON_HAND_INVENTORY",
            "UNSELLABLE_ON_HAND_INVENTORY",
            /* total on-hand units & value */
            ("SELLABLE_ON_HAND_UNITS" + COALESCE("UNSELLABLE_ON_HAND_UNITS",0))      AS "TOTAL_ON_HAND_UNITS",
            ("SELLABLE_ON_HAND_INVENTORY" + COALESCE("UNSELLABLE_ON_HAND_INVENTORY",0)) AS "TOTAL_ON_HAND_VALUE"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."RETAIL_ANALYTICS_INVENTORY"
    WHERE   "DISTRIBUTOR_VIEW" = 'Manufacturing'
      AND   "DATE" BETWEEN '2022-01-07' AND '2022-02-06'
),

ppm_window AS (                --------------------  NET-PPM  (Distributor receipts)
    SELECT  "RECEIVE_DATE"                         AS "DATE",
            SUM("QUANTITY")        AS "NET_RECEIVED_UNITS",
            SUM("NET_RECEIPTS")    AS "NET_RECEIVED_VALUE",
            CASE WHEN SUM("QUANTITY") <> 0
                 THEN SUM("NET_RECEIPTS") / SUM("QUANTITY")
            END                    AS "AVG_NET_PPM"
    FROM    AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    WHERE   "RECEIVE_DATE" BETWEEN '2022-01-07' AND '2022-02-06'
    GROUP BY "RECEIVE_DATE"
)

SELECT
       s."DATE",
       s."ASIN",
       /*  Sales metrics */
       COALESCE(s."ORDERED_UNITS",0)     AS "TOTAL_ORDERED_UNITS",
       COALESCE(s."ORDERED_REVENUE",0)   AS "TOTAL_ORDERED_REVENUE",
       s."AVG_SELLING_PRICE",
       COALESCE(s."SHIPPED_UNITS",0)     AS "SHIPPED_UNITS",
       COALESCE(s."SHIPPED_REVENUE",0)   AS "SHIPPED_REVENUE",

       /*  Traffic metrics */
       t."GLANCE_VIEWS",
       CASE
           WHEN t."GLANCE_VIEWS" > 0
           THEN COALESCE(s."ORDERED_UNITS",0) / t."GLANCE_VIEWS"
       END                               AS "CONVERSION_RATE",
       t."PERIOD",

       /*  Inventory metrics */
       i."TOTAL_ON_HAND_UNITS",
       i."TOTAL_ON_HAND_VALUE",

       /*  Net-PPM / receipts */
       ppm."NET_RECEIVED_UNITS",
       ppm."NET_RECEIVED_VALUE",
       ppm."AVG_NET_PPM",

       /*  Place-holders for metrics not present in sample data */
       NULL::FLOAT  AS "AVG_PROCURABLE_PRODUCT_OOS",
       NULL::FLOAT  AS "OPEN_PO_QUANTITIES",
       NULL::FLOAT  AS "UNFILLED_CUSTOMER_ORDERED_UNITS",
       NULL::FLOAT  AS "AVG_VENDOR_CONFIRMATION_RATE",
       NULL::FLOAT  AS "AVG_RECEIVE_FILL_RATE",
       NULL::FLOAT  AS "SELL_THROUGH_RATE",
       NULL::FLOAT  AS "VENDOR_LEAD_TIME"

FROM   sales_window      s
LEFT JOIN traffic_window t
       ON  s."DATE" = t."DATE"
       AND s."ASIN" = t."ASIN"
LEFT JOIN inventory_window i
       ON  s."DATE" = i."DATE"
       AND s."ASIN" = i."ASIN"
LEFT JOIN ppm_window     ppm
       ON  s."DATE" = ppm."DATE"

ORDER BY s."DATE", s."ASIN";