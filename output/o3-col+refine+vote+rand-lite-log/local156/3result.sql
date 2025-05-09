WITH region_year_stats AS (   -- annual totals + average cost
    SELECT bm."region"                                           AS region,
           substr(bt."txn_date", 7, 4)                           AS calendar_year,
           SUM(bt."quantity")                                    AS total_qty,
           SUM(bt."quantity" * bp."price")                       AS total_cost_usd,
           SUM(bt."quantity" * bp."price") / SUM(bt."quantity")  AS avg_price
    FROM   "bitcoin_transactions"  bt
    JOIN   "bitcoin_members"       bm  ON bt."member_id" = bm."member_id"
    JOIN   "bitcoin_prices"        bp
           ON  bp."ticker"      = bt."ticker"
           AND bp."market_date" = bt."txn_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
    GROUP  BY bm."region", calendar_year
),
region_year_excl_first AS (        -- remove each region's first year
    SELECT *
    FROM (
            SELECT rys.*,
                   MIN(calendar_year) OVER (PARTITION BY region) AS first_year
            FROM   region_year_stats rys
         ) t
    WHERE  calendar_year > first_year
),
rank_and_change AS (               -- compute rank and previous avg_price
    SELECT region,
           calendar_year,
           ROUND(avg_price, 4)                                            AS avg_purchase_price_usd,
           RANK() OVER (PARTITION BY calendar_year
                        ORDER BY avg_price DESC)                          AS region_rank,
           LAG(avg_price) OVER (PARTITION BY region
                                ORDER BY calendar_year)                   AS prev_avg_price
    FROM   region_year_excl_first
)
SELECT region,
       calendar_year,
       avg_purchase_price_usd,
       region_rank,
       ROUND(100.0 * (avg_purchase_price_usd - prev_avg_price)
                   / prev_avg_price, 2)                                   AS annual_pct_change
FROM   rank_and_change
ORDER  BY calendar_year,
          region_rank;