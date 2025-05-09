/*-----------------------------------------------------------
Daily detailed sales report per ASIN – Manufacturing items  
30-day window : 08-Jan-2022 → 06-Feb-2022  (inclusive)
-----------------------------------------------------------*/
WITH
/*-----------------------------------------------------------------
1) 30-day calendar window
-----------------------------------------------------------------*/
window_dates AS (
    SELECT  TO_DATE('2022-01-08') AS "START_DT",
            TO_DATE('2022-02-06') AS "END_DT"
),

/*-----------------------------------------------------------------
2) Daily Net-PPM (average net receipts per unit) – grain = DATE
-----------------------------------------------------------------*/
daily_ppm AS (
    SELECT  TO_DATE("RECEIVE_DATE")                                  AS "DATE",
            AVG("NET_RECEIPTS" / NULLIF("QUANTITY",0))              AS "AVG_NET_PPM"
    FROM    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."PAYMENTS_DISTRIBUTOR_SHIPMENT_DETAILS"
    JOIN    window_dates w
          ON TO_DATE("RECEIVE_DATE") BETWEEN w."START_DT" AND w."END_DT"
    GROUP BY 1
),

/*-----------------------------------------------------------------
3) Inventory snapshot – derive on-hand & other metrics
-----------------------------------------------------------------*/
inv AS (
    SELECT  TO_DATE(i."DATE")                                        AS "DATE",
            i."ASIN",
            i."DISTRIBUTOR_VIEW",
            i."PROCURABLE_PRODUCT_OOS"          AS "PROCURABLE_OOS",
            i."NET_RECEIVED_UNITS",
            i."NET_RECEIVED"                    AS "NET_RECEIVED_VALUE",
            i."OPEN_PURCHASE_ORDER_QUANTITY"    AS "OPEN_PO_QTY",
            i."UNFILLED_CUSTOMER_ORDERED_UNITS" AS "UNFILLED_CUST_ORD_UNITS",
            i."VENDOR_CONFIRMATION_RATE",
            i."RECEIVE_FILL_RATE",
            i."SELL_THROUGH_RATE",
            /* on-hand */
            (i."SELLABLE_ON_HAND_UNITS" + i."UNSELLABLE_ON_HAND_UNITS")           AS "ON_HAND_UNITS",
            (i."SELLABLE_ON_HAND_INVENTORY" + i."UNSELLABLE_ON_HAND_INVENTORY")   AS "ON_HAND_VALUE"
    FROM    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_INVENTORY" i
    JOIN    window_dates w
          ON TO_DATE(i."DATE") BETWEEN w."START_DT" AND w."END_DT"
    WHERE   i."DISTRIBUTOR_VIEW" = 'Manufacturing'
),

/*-----------------------------------------------------------------
4) SALES + TRAFFIC at daily ASIN grain
-----------------------------------------------------------------*/
sales_traffic AS (
    SELECT  TO_DATE(s."DATE")                        AS "DATE",
            s."ASIN",
            s."DISTRIBUTOR_VIEW",
            s."ORDERED_UNITS",
            s."ORDERED_REVENUE",
            s."SHIPPED_UNITS",
            s."SHIPPED_REVENUE",
            t."GLANCE_VIEWS"
    FROM    "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_SALES"   s
    LEFT JOIN "AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET"."PUBLIC"."RETAIL_ANALYTICS_TRAFFIC" t
           ON  TO_DATE(s."DATE") = TO_DATE(t."DATE")
           AND s."ASIN"          = t."ASIN"
           AND s."DISTRIBUTOR_VIEW" = t."DISTRIBUTOR_VIEW"
    JOIN    window_dates w
          ON TO_DATE(s."DATE") BETWEEN w."START_DT" AND w."END_DT"
    WHERE   s."DISTRIBUTOR_VIEW" = 'Manufacturing'
)

/*-----------------------------------------------------------------
5) Final daily report
-----------------------------------------------------------------*/
SELECT  st."DATE",
        st."ASIN",
        /*  Sales metrics  */
        st."ORDERED_UNITS",
        st."ORDERED_REVENUE",
        (st."ORDERED_REVENUE" / NULLIF(st."ORDERED_UNITS",0))           AS "AVG_SELL_PRICE",
        st."GLANCE_VIEWS",
        (st."SHIPPED_UNITS" / NULLIF(st."GLANCE_VIEWS",0))              AS "CONVERSION_RATE",
        st."SHIPPED_UNITS",
        st."SHIPPED_REVENUE",
        /*  Net-PPM  */
        p."AVG_NET_PPM",
        /*  Inventory metrics  */
        i."PROCURABLE_OOS"                                              AS "AVG_PROCURABLE_OOS",
        i."ON_HAND_UNITS",
        i."ON_HAND_VALUE",
        i."NET_RECEIVED_UNITS",
        i."NET_RECEIVED_VALUE",
        i."OPEN_PO_QTY",
        i."UNFILLED_CUST_ORD_UNITS",
        /*  Rates  */
        i."VENDOR_CONFIRMATION_RATE",
        i."RECEIVE_FILL_RATE",
        i."SELL_THROUGH_RATE"
FROM    sales_traffic  st
LEFT JOIN inv        i  ON st."DATE" = i."DATE"
                        AND st."ASIN" = i."ASIN"
LEFT JOIN daily_ppm  p  ON st."DATE" = p."DATE"
ORDER BY st."DATE" ASC,
         st."ASIN";