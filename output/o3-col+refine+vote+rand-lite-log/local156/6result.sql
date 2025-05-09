WITH region_first AS (
    /* each region’s first year of BTC buying activity */
    SELECT bm."region",
           MIN(CAST(SUBSTR(bt."txn_date", -4) AS INTEGER)) AS first_year
    FROM   "bitcoin_transactions" bt
    JOIN   "bitcoin_members"       bm ON bt."member_id" = bm."member_id"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
    GROUP  BY bm."region"
),
yearly_cost AS (
    /* yearly totals and average cost per BTC */
    SELECT CAST(SUBSTR(bt."txn_date", -4) AS INTEGER)               AS year,
           bm."region",
           SUM(bt."quantity" * bp."price")                          AS total_spent_usd,
           SUM(bt."quantity")                                       AS total_qty,
           SUM(bt."quantity" * bp."price") / SUM(bt."quantity")     AS avg_price_usd_per_btc
    FROM   "bitcoin_transactions" bt
    JOIN   "bitcoin_members"  bm ON bt."member_id" = bm."member_id"
    JOIN   "bitcoin_prices"   bp ON bp."ticker" = 'BTC'
                                 AND bp."market_date" = bt."txn_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
    GROUP  BY year, bm."region"
),
filtered_cost AS (
    /* exclude the first-ever year for every region */
    SELECT yc.*
    FROM   yearly_cost yc
    JOIN   region_first rf ON yc."region" = rf."region"
    WHERE  yc."year" > rf."first_year"
),
ranked AS (
    /* rank regions each year and fetch previous year’s avg cost */
    SELECT fc.*,
           RANK() OVER (PARTITION BY fc.year
                        ORDER BY fc.avg_price_usd_per_btc DESC)      AS region_rank,
           LAG(fc.avg_price_usd_per_btc)
               OVER (PARTITION BY fc."region" ORDER BY fc.year)      AS prev_year_price
    FROM   filtered_cost fc
)
SELECT year,
       region,
       ROUND(avg_price_usd_per_btc, 4)                               AS avg_cost_usd,
       region_rank,
       ROUND(100.0 * (avg_price_usd_per_btc - prev_year_price)
                   / prev_year_price, 2)                             AS yoy_pct_change
FROM   ranked
ORDER  BY year, region_rank;