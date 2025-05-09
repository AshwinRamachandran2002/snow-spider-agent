WITH txn_prices AS (       -- match every BTC buy with its closing price on the same day
    SELECT
        t."member_id",
        m."region",
        TO_DATE(t."txn_date", 'DD-MM-YYYY')              AS "txn_dt",
        YEAR(TO_DATE(t."txn_date", 'DD-MM-YYYY'))        AS "txn_year",
        t."quantity",
        p."price"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_MEMBERS     m
          ON t."member_id" = m."member_id"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES      p
          ON   p."ticker"      = t."ticker"
          AND  p."ticker"      = 'BTC'
          AND  TO_DATE(p."market_date", 'DD-MM-YYYY') = TO_DATE(t."txn_date", 'DD-MM-YYYY')
    WHERE t."txn_type" = 'BUY'
      AND t."ticker"   = 'BTC'
), region_year_summary AS (  -- annual totals & derived average cost
    SELECT
        "region",
        "txn_year"                                            AS "year",
        SUM("quantity" * "price")  AS "total_spent",
        SUM("quantity")             AS "total_qty",
        SUM("quantity" * "price") / NULLIF(SUM("quantity"),0) AS "avg_price"
    FROM txn_prices
    GROUP BY "region", "txn_year"
), remove_first_year AS (     -- eliminate a region’s first-ever year
    SELECT r.*
    FROM region_year_summary r
    JOIN (
           SELECT "region",
                  MIN("year") AS first_year
           FROM region_year_summary
           GROUP BY "region"
         ) f
      ON r."region" = f."region"
    WHERE r."year" <> f.first_year
), ranked AS (                -- rank regions by average price each year
    SELECT
        "year",
        "region",
        "avg_price",
        RANK() OVER (PARTITION BY "year"
                     ORDER BY "avg_price" DESC NULLS LAST)     AS "region_rank"
    FROM remove_first_year
), pct_change AS (            -- year-on-year % change for every region
    SELECT
        r.*,
        ROUND(
              100 * ( "avg_price" - LAG("avg_price") OVER (PARTITION BY "region"
                                                            ORDER BY "year") )
              / NULLIF( LAG("avg_price") OVER (PARTITION BY "region"
                                                ORDER BY "year") , 0 )
        ,4)                                 AS "pct_change_vs_prev_year"
    FROM ranked r
)
SELECT
    "year",
    "region",
    ROUND("avg_price",4)                     AS "avg_purchase_price",
    "region_rank",
    "pct_change_vs_prev_year"
FROM pct_change
ORDER BY "year", "region_rank", "region";