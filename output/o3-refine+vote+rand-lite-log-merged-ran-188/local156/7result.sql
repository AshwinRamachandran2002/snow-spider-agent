WITH tx AS (  /* 1.  all BTC buy transactions joined to daily price and member region */
    SELECT
        bm."region",
        substr(bt."txn_date", 7)              AS year,              -- '01-01-2017' → '2017'
        bt."quantity",
        bp."price",
        bt."quantity" * bp."price"            AS amount_spent
    FROM "bitcoin_transactions" bt
    JOIN "bitcoin_members"      bm ON bt."member_id" = bm."member_id"
    JOIN "bitcoin_prices"       bp ON bp."ticker" = bt."ticker"
                                   AND bp."market_date" = bt."txn_date"
    WHERE bt."ticker" = 'BTC'
      AND bt."txn_type" = 'BUY'
),
region_year_stats AS (          /* 2.  yearly aggregates per region */
    SELECT
        "region",
        year,
        SUM(amount_spent)                    AS total_spent,
        SUM("quantity")                      AS total_qty,
        SUM(amount_spent) / SUM("quantity")  AS avg_price
    FROM tx
    GROUP BY "region", year
),
region_year_filtered AS (        /* 3.  flag the first year per region */
    SELECT
        rys.*,
        ROW_NUMBER() OVER (PARTITION BY "region" ORDER BY CAST(year AS INTEGER)) AS rn
    FROM region_year_stats rys
),
region_year_valid AS (           /* 4.  exclude each region’s first year */
    SELECT "region", year, avg_price
    FROM   region_year_filtered
    WHERE  rn > 1
),
ranked AS (                      /* 5.  rank regions by avg_price, per year */
    SELECT
        "region",
        year,
        avg_price,
        RANK() OVER (PARTITION BY year ORDER BY avg_price DESC) AS region_rank
    FROM region_year_valid
),
final_calc AS (                  /* 6.  compute YoY % change for each region */
    SELECT
        "region",
        year,
        avg_price,
        region_rank,
        ROUND(
            (avg_price - LAG(avg_price) OVER (PARTITION BY "region" ORDER BY CAST(year AS INTEGER)))
            / LAG(avg_price)      OVER (PARTITION BY "region" ORDER BY CAST(year AS INTEGER))
            * 100, 4
        ) AS pct_change_vs_prev_year
    FROM ranked
)
SELECT
    "region",
    year,
    ROUND(avg_price, 4)                AS avg_purchase_price,
    region_rank,
    pct_change_vs_prev_year
FROM   final_calc
ORDER  BY CAST(year AS INTEGER),
          region_rank,
          "region";