WITH order_data AS (
    /*-----------------------------------------------------------------
      Bring together every order_item with its product information
      and convert the micro‑second epoch to a month bucket.
    -----------------------------------------------------------------*/
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP( "oi"."created_at" / 1000000 )
        )                                         AS order_month ,
        "p"."category"                            AS product_category ,
        "oi"."order_id"                           AS order_id ,
        "oi"."sale_price"                         AS sale_price ,
        "p"."cost"                                AS cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      AS "p"
          ON "oi"."product_id" = "p"."id"
    /* only the months we need (June‑Dec 2019)                                        */
    WHERE DATE_TRUNC(
              'month',
              TO_TIMESTAMP( "oi"."created_at" / 1000000 )
          ) BETWEEN '2019-06-01' AND '2019-12-01'
), 
monthly_stats AS (
    /*-----------------------------------------------------------------
      Aggregate to month + category
    -----------------------------------------------------------------*/
    SELECT
        order_month ,
        product_category ,
        COUNT( DISTINCT order_id )                          AS total_orders ,
        SUM( sale_price )                                   AS total_revenue ,
        SUM( sale_price - cost )                            AS total_profit
    FROM order_data
    GROUP BY order_month , product_category
), 
stats_with_growth AS (
    /*-----------------------------------------------------------------
      Bring in previous‑month values (June will serve as the baseline)
    -----------------------------------------------------------------*/
    SELECT
        TO_CHAR( order_month , 'YYYY-MM' )                  AS month ,
        product_category ,
        total_orders ,
        total_revenue ,
        total_profit ,
        LAG( total_orders  ) OVER ( PARTITION BY product_category
                                    ORDER BY order_month )  AS prev_orders ,
        LAG( total_revenue ) OVER ( PARTITION BY product_category
                                    ORDER BY order_month )  AS prev_revenue ,
        LAG( total_profit  ) OVER ( PARTITION BY product_category
                                    ORDER BY order_month )  AS prev_profit
    FROM monthly_stats
) 
/*-----------------------------------------------------------------
  Final selection:
  • omit June 2019 from the output
  • calculate MoM growth
-----------------------------------------------------------------*/
SELECT
    month ,
    product_category ,
    total_orders ,
    total_revenue ,
    total_profit ,
    CASE WHEN prev_orders  IS NULL OR prev_orders  = 0 THEN NULL
         ELSE ( total_orders  - prev_orders  ) / prev_orders  END AS orders_mom_growth ,
    CASE WHEN prev_revenue IS NULL OR prev_revenue = 0 THEN NULL
         ELSE ( total_revenue - prev_revenue ) / prev_revenue END AS revenue_mom_growth ,
    CASE WHEN prev_profit  IS NULL OR prev_profit  = 0 THEN NULL
         ELSE ( total_profit  - prev_profit  ) / prev_profit  END AS profit_mom_growth
FROM stats_with_growth
WHERE month > '2019-06'          -- drop June from the final report
ORDER BY month , product_category ;