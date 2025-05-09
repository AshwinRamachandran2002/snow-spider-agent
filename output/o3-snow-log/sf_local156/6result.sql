WITH txn_buy AS (            -- 1. keep only BTC purchase transactions
    SELECT  "member_id",
            "quantity",
            "txn_date",      -- format DD-MM-YYYY
            "ticker"
    FROM    BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS
    WHERE   "txn_type" = 'BUY'
      AND   "ticker"  = 'BTC'
),
txn_with_price AS (          -- 2. attach daily BTC price and member region
    SELECT  tb."member_id",
            bm."region",
            TO_DATE(tb."txn_date", 'DD-MM-YYYY')           AS txn_dt,
            YEAR(TO_DATE(tb."txn_date", 'DD-MM-YYYY'))     AS txn_year,
            tb."quantity",
            bp."price"
    FROM    txn_buy tb
    JOIN    BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES bp
           ON bp."ticker" = tb."ticker"
          AND TO_DATE(bp."market_date", 'DD-MM-YYYY') = TO_DATE(tb."txn_date", 'DD-MM-YYYY')
    JOIN    BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_MEMBERS bm
           ON bm."member_id" = tb."member_id"
),
region_year_agg AS (         -- 3. yearly spend / qty by region
    SELECT  "region",
            txn_year AS "year",
            SUM("quantity" * "price")          AS total_spent,
            SUM("quantity")                    AS total_qty,
            SUM("quantity" * "price") / NULLIF(SUM("quantity"),0) AS avg_purchase_price
    FROM    txn_with_price
    GROUP BY "region", txn_year
),
exclude_first_year AS (      -- 4. drop each region’s first year
    SELECT  *
    FROM    region_year_agg
    QUALIFY "year" > MIN("year") OVER (PARTITION BY "region")
),
rank_and_change AS (         -- 5. rank regions by yearly avg price & calc % change
    SELECT  "year",
            "region",
            avg_purchase_price,
            DENSE_RANK() OVER (PARTITION BY "year"
                               ORDER BY avg_purchase_price DESC NULLS LAST)   AS region_rank,
            (avg_purchase_price
             - LAG(avg_purchase_price) OVER (PARTITION BY "region" ORDER BY "year"))
            / LAG(avg_purchase_price) OVER (PARTITION BY "region" ORDER BY "year") * 100  AS pct_change
    FROM    exclude_first_year
)
SELECT  "year",
        "region",
        ROUND(avg_purchase_price, 4)  AS avg_purchase_price,
        region_rank,
        ROUND(pct_change, 4)          AS pct_change
FROM    rank_and_change
ORDER BY "year", region_rank NULLS LAST;