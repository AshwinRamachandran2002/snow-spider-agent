WITH txn_prices AS (   -- all BTC purchase transactions joined to the daily BTC price
    SELECT
        mb."region"                                               AS region ,
        YEAR( TO_DATE(tr."txn_date" , 'DD-MM-YYYY') )             AS txn_year ,
        tr."quantity"                                             AS qty ,
        pr."price"                                                AS unit_price
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS"  tr
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_MEMBERS"       mb
          ON  tr."member_id" = mb."member_id"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"        pr
          ON  pr."ticker" = tr."ticker"
          AND TO_DATE(pr."market_date",'DD-MM-YYYY')
              = TO_DATE(tr."txn_date",'DD-MM-YYYY')
    WHERE tr."txn_type" = 'BUY'
      AND tr."ticker"   = 'BTC'
),                                                              -- yearly region-level spend & qty
region_year AS (
    SELECT
        region ,
        txn_year                              AS year ,
        SUM(qty * unit_price)                AS total_spent ,
        SUM(qty)                             AS total_qty ,
        SUM(qty * unit_price) /
        NULLIF( SUM(qty) ,0)                 AS avg_purchase_price
    FROM txn_prices
    GROUP BY region , txn_year
),                                                              -- mark each region’s first year
region_year_flag AS (
    SELECT
        ry.* ,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY year)     AS year_seq
    FROM region_year ry
),                                                              -- exclude first year for each region
filtered AS (
    SELECT *
    FROM region_year_flag
    WHERE year_seq > 1
)
SELECT
    region ,
    year ,
    ROUND(avg_purchase_price , 4)                                       AS avg_purchase_price ,
    RANK()  OVER (PARTITION BY year ORDER BY avg_purchase_price DESC)   AS region_rank ,
    ROUND(
        (avg_purchase_price 
         - LAG(avg_purchase_price) OVER (PARTITION BY region ORDER BY year))
        / LAG(avg_purchase_price)  OVER (PARTITION BY region ORDER BY year)
        * 100
    ,4)                                                                AS pct_change_vs_prev_year
FROM filtered
ORDER BY year , region_rank NULLS LAST;