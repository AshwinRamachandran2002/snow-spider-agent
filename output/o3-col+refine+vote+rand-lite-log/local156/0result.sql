WITH yearly_totals AS (           -- 1.  Dollars and quantity bought each year/region
    SELECT
        bm."region",
        SUBSTR(bt."txn_date", 7, 4)              AS "year",
        SUM(bt."quantity" * bp."price")          AS total_spent,
        SUM(bt."quantity")                       AS total_qty
    FROM   "bitcoin_transactions"  bt
    JOIN   "bitcoin_members"       bm ON bt."member_id" = bm."member_id"
    JOIN   "bitcoin_prices"        bp
           ON  bt."ticker" = bp."ticker"
           AND bt."txn_date" = bp."market_date"
    WHERE  bt."txn_type" = 'BUY'
    GROUP  BY bm."region", SUBSTR(bt."txn_date", 7, 4)
),
avg_price AS (                 -- 2.  Annual average purchase price & first-year flag
    SELECT
        region,
        year,
        total_spent / total_qty                   AS avg_purchase_price,
        ROW_NUMBER() OVER (PARTITION BY region
                           ORDER BY year)         AS rn
    FROM   yearly_totals
),
filtered AS (                  -- 3.  Drop each region’s first recorded year
    SELECT
        region,
        year,
        avg_purchase_price
    FROM   avg_price
    WHERE  rn > 1
),
ranked AS (                    -- 4.  Rank regions by cost and add YoY % change
    SELECT
        year,
        region,
        avg_purchase_price,
        RANK() OVER (PARTITION BY year
                     ORDER BY avg_purchase_price DESC)      AS cost_rank,
        ROUND(
              (avg_purchase_price -
               LAG(avg_purchase_price) OVER (PARTITION BY region ORDER BY year)
              ) * 100.0 /
              LAG(avg_purchase_price) OVER (PARTITION BY region ORDER BY year),
              4
        )                                                   AS pct_change_vs_prev_year
    FROM   filtered
)
SELECT
    year,
    region,
    ROUND(avg_purchase_price, 4)  AS avg_purchase_price,
    cost_rank,
    pct_change_vs_prev_year
FROM   ranked
ORDER  BY year,
          cost_rank;