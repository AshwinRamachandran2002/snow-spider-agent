WITH yearly_totals AS (
    /* 1.  Total USD spent and BTC purchased per region & year               */
    SELECT bm.region,
           SUBSTR(bt.txn_date, 7, 4)                AS txn_year,
           SUM(bt.quantity * bp.price)              AS usd_spent,
           SUM(bt.quantity)                         AS qty_btc
    FROM bitcoin_transactions  AS bt
    JOIN bitcoin_members       AS bm ON bt.member_id  = bm.member_id
    JOIN bitcoin_prices        AS bp ON bp.ticker     = bt.ticker
                                    AND bp.market_date = bt.txn_date   -- both dd-mm-yyyy
    WHERE bt.ticker   = 'BTC'
      AND bt.txn_type = 'BUY'
    GROUP BY bm.region, txn_year
),
first_year AS (
    /* 2.  Earliest BTC-buy year for every region                            */
    SELECT region,
           MIN(txn_year) AS first_year
    FROM yearly_totals
    GROUP BY region
),
avg_price AS (
    /* 3.  Average price per BTC for each region/year, 
            excluding the region’s first year                               */
    SELECT y.region,
           y.txn_year,
           y.usd_spent / y.qty_btc        AS avg_price_usd
    FROM yearly_totals y
    JOIN first_year   f  ON y.region = f.region
    WHERE y.txn_year > f.first_year
)
/* 4.  Rank regions by annual average price and compute YoY % change        */
SELECT region,
       txn_year,
       ROUND(avg_price_usd, 4)                                                AS avg_price_usd,
       RANK() OVER (PARTITION BY txn_year ORDER BY avg_price_usd DESC)        AS price_rank,
       ROUND(
           100.0 * (avg_price_usd - LAG(avg_price_usd) 
                                 OVER (PARTITION BY region ORDER BY txn_year))
           / LAG(avg_price_usd) OVER (PARTITION BY region ORDER BY txn_year),
           2
       )                                                                      AS pct_change_vs_prev_year
FROM avg_price
ORDER BY txn_year,
         price_rank;