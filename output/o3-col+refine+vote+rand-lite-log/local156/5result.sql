WITH region_year_price AS (
    /* 1.  Average BTC purchase price (total_spent / qty) per region & year */
    SELECT
        bm."region"                                AS region,
        substr(bt."txn_date",7,4)                  AS year,        -- yyyy
        SUM(bt."quantity" * bp."price") * 1.0
        / SUM(bt."quantity")                       AS avg_price,
        ROW_NUMBER() OVER (
            PARTITION BY bm."region"
            ORDER BY substr(bt."txn_date",7,4)
        )                                          AS rn           -- identify first year per region
    FROM   "bitcoin_transactions"  bt
    JOIN   "bitcoin_members"       bm  ON bt."member_id" = bm."member_id"
    JOIN   "bitcoin_prices"        bp
           ON  bp."ticker"      = bt."ticker"
           AND bp."market_date" = bt."txn_date"
    WHERE  bt."ticker"   = 'BTC'
      AND  bt."txn_type" = 'BUY'
    GROUP  BY bm."region", substr(bt."txn_date",7,4)
),
/* 2.  Remove the first year of data for every region */
filtered AS (
    SELECT region, year, avg_price
    FROM   region_year_price
    WHERE  rn > 1
)
SELECT
    region,
    year,
    ROUND(avg_price,4)                                                   AS avg_price,
    RANK() OVER (PARTITION BY year ORDER BY avg_price DESC)              AS region_rank,
    ROUND(
        100.0 * (
            avg_price - LAG(avg_price) OVER (PARTITION BY region ORDER BY year)
        )
        / LAG(avg_price) OVER (PARTITION BY region ORDER BY year)
    ,2)                                                                  AS pct_change_vs_prev_year
FROM   filtered
ORDER BY year, region_rank;