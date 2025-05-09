WITH txn_with_price AS (          -- 1. add the $ price for every BTC buy
    SELECT  bt.txn_id,
            bm.region,
            bt.ticker,
            bt.txn_date,
            CAST(substr(bt.txn_date,-4) AS INTEGER)   AS yr,      -- yyyy
            bt.quantity,
            bp.price,
            (bt.quantity*bp.price)                    AS amt_spent
    FROM    bitcoin_transactions  bt
    JOIN    bitcoin_members       bm ON bm.member_id = bt.member_id
    JOIN    bitcoin_prices        bp 
                 ON  bp.ticker     = bt.ticker 
                 AND bp.market_date = bt.txn_date
    WHERE   bt.ticker   = 'BTC'
      AND   bt.txn_type = 'BUY'
),
region_year_avg AS (             -- 2. yearly average purchase price per region
    SELECT  region,
            yr,
            SUM(amt_spent)                       AS tot_spent,
            SUM(quantity)                        AS tot_qty,
            SUM(amt_spent)*1.0 / SUM(quantity)   AS avg_price,
            ROW_NUMBER() OVER (PARTITION BY region ORDER BY yr) AS rn
    FROM    txn_with_price
    GROUP BY region, yr
),
filtered_avg AS (                -- 3. drop the first‑year data for every region
    SELECT * 
    FROM   region_year_avg
    WHERE  rn > 1
),
ranked AS (                       -- 4. rank regions inside every year
    SELECT  yr                                                       AS year,
            region,
            avg_price,
            DENSE_RANK() OVER (PARTITION BY yr ORDER BY avg_price DESC, region) AS region_rank,
            LAG(avg_price) OVER (PARTITION BY region ORDER BY yr)              AS prev_avg
    FROM    filtered_avg
)
SELECT  year,
        region,
        ROUND(avg_price,4)                              AS avg_price,
        region_rank,
        ROUND( (avg_price - prev_avg)*100.0 / prev_avg ,4)  AS pct_change
FROM    ranked
ORDER BY year,
         region_rank,
         region;