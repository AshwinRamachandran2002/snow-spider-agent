/*-------------------------------------------------------------
  1.  Pull only BTC “BUY” transactions and convert the  
      string transaction date to a DATE data-type.
-------------------------------------------------------------*/
WITH buy_txns AS (
    SELECT
        bt."member_id",
        bt."quantity",
        TO_DATE(bt."txn_date",'DD-MM-YYYY')      AS "txn_date"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS" bt
    WHERE bt."txn_type" = 'BUY'
      AND bt."ticker"   = 'BTC'
),

/*-------------------------------------------------------------
  2.  Join on member region and daily BTC closing price
      (price on the same calendar date).
-------------------------------------------------------------*/
price_txns AS (
    SELECT
        bm."region", 
        b."quantity",
        b."txn_date",
        bp."price"                                AS "btc_price"
    FROM buy_txns b
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_MEMBERS"  bm
          ON b."member_id" = bm."member_id"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"   bp
          ON bp."ticker" = 'BTC'
         AND TO_DATE(bp."market_date",'DD-MM-YYYY') = b."txn_date"
),

/*-------------------------------------------------------------
  3.  Aggregate to annual level – total $ spent and
      total quantity bought, then derive average price.
-------------------------------------------------------------*/
region_year_agg AS (
    SELECT
        "region",
        YEAR("txn_date")                          AS "calendar_year",
        SUM("quantity" * "btc_price")             AS "total_spent",
        SUM("quantity")                           AS "total_qty",
        SUM("quantity" * "btc_price")
        / NULLIF(SUM("quantity"),0)               AS "avg_price"
    FROM price_txns
    GROUP BY "region", YEAR("txn_date")
),

/*-------------------------------------------------------------
  4.  Exclude the first transaction year for every region.
-------------------------------------------------------------*/
exclude_first_year AS (
    SELECT *
    FROM (
        SELECT
            rya.*,
            MIN("calendar_year") 
                OVER (PARTITION BY "region")      AS "first_year"
        FROM region_year_agg rya
    )
    WHERE "calendar_year" > "first_year"
),

/*-------------------------------------------------------------
  5.  Rank regions by annual average purchase price and
      calculate YoY % change in cost per region.
-------------------------------------------------------------*/
final_calc AS (
    SELECT
        "calendar_year",
        "region",
        "avg_price",
        RANK() OVER (PARTITION BY "calendar_year"
                     ORDER BY "avg_price" DESC NULLS LAST)  AS "region_rank",
        100 * ( "avg_price" 
              - LAG("avg_price") OVER (PARTITION BY "region"
                                        ORDER BY "calendar_year") )
              / LAG("avg_price") OVER (PARTITION BY "region"
                                        ORDER BY "calendar_year")  AS "pct_change_vs_prev_year"
    FROM exclude_first_year
)

SELECT
    "calendar_year",
    "region",
    "avg_price",
    "region_rank",
    "pct_change_vs_prev_year"
FROM final_calc
ORDER BY "calendar_year", "region_rank";