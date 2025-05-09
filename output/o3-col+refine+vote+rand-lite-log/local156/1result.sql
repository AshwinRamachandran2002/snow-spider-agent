/*  Annual average BTC purchase price by region, rank within each year,
    and year-over-year % change (first calendar year per region is omitted)  */

WITH region_year_costs AS (           -- 1) total spend & qty per region/year
    SELECT
        m."region",
        substr(t."txn_date", -4)                 AS "year",
        SUM(t."quantity"
            * p."price"
            * (1 + t."percentage_fee" / 100.0)) AS "total_spent",
        SUM(t."quantity")                       AS "total_qty"
    FROM "bitcoin_transactions"  AS t
    JOIN "bitcoin_members"       AS m  ON m."member_id" = t."member_id"
    JOIN "bitcoin_prices"        AS p  ON p."ticker"    = t."ticker"
                                       AND p."market_date" = t."txn_date"
    WHERE t."ticker" = 'BTC'
      AND t."txn_type" = 'BUY'
    GROUP BY m."region", substr(t."txn_date", -4)
),
region_year_avg AS (                -- 2) average price & first-year flag
    SELECT
        "region",
        "year",
        ROUND("total_spent" / "total_qty", 4)          AS "avg_price",
        ROW_NUMBER() OVER (
            PARTITION BY "region"
            ORDER BY "year"
        )                                              AS "yr_rank"
    FROM region_year_costs
),
filtered_avg AS (                   -- 3) drop each region’s first calendar year
    SELECT "region", "year", "avg_price"
    FROM   region_year_avg
    WHERE  "yr_rank" > 1
),
ranked AS (                          -- 4) rank regions by avg_price each year
    SELECT
        "region",
        "year",
        "avg_price",
        RANK() OVER (
            PARTITION BY "year"
            ORDER BY "avg_price" DESC
        )                            AS "region_rank"
    FROM filtered_avg
)
SELECT
    "region",
    "year",
    "avg_price",
    "region_rank",
    ROUND(
        ( "avg_price"
          - LAG("avg_price") OVER (
                PARTITION BY "region"
                ORDER BY "year"
            )
        ) * 100.0
        / LAG("avg_price") OVER (
                PARTITION BY "region"
                ORDER BY "year"
          )
    , 2)                             AS "pct_change_vs_prev_year"
FROM ranked
ORDER BY "year", "region_rank", "region";