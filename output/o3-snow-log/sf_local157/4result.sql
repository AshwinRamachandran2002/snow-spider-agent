/*  Daily % change in trading volume for every ticker
    – Aug-01-2021 → Aug-10-2021
    – “K” → *1 000, “M” → *1 000 000, “-” → 0
    – Previous-day volume skips zeros (IGNORE NULLS)                                   */

WITH base AS (
    SELECT
        "ticker",
        TO_DATE("market_date", 'DD-MM-YYYY')                                   AS "mkt_dt",
        /* convert text volume to numeric */
        CASE
            WHEN RIGHT("volume", 1) = 'K' THEN TO_NUMBER(REPLACE("volume", 'K', '')) * 1000
            WHEN RIGHT("volume", 1) = 'M' THEN TO_NUMBER(REPLACE("volume", 'M', '')) * 1000000
            WHEN "volume" = '-'            THEN 0
            ELSE TO_NUMBER("volume")
        END                                                                    AS "vol_num"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"
    WHERE TO_DATE("market_date", 'DD-MM-YYYY')
          BETWEEN '2021-08-01' AND '2021-08-10'
), lagged AS (
    SELECT
        "ticker",
        "mkt_dt",
        "vol_num",
        /* previous non-zero volume */
        LAG(NULLIF("vol_num", 0)) IGNORE NULLS
        OVER (PARTITION BY "ticker" ORDER BY "mkt_dt")                         AS "prev_vol"
    FROM base
)
SELECT
    "ticker",
    TO_CHAR("mkt_dt", 'DD-MM-YYYY')                                            AS "market_date",
    "vol_num"                                                                  AS "volume",
    "prev_vol",
    CASE
        WHEN "prev_vol" IS NULL OR "prev_vol" = 0 THEN NULL
        ELSE ROUND(100 * ("vol_num" - "prev_vol") / "prev_vol", 2)
    END                                                                        AS "pct_change_vol"
FROM lagged
ORDER BY "ticker", "mkt_dt";