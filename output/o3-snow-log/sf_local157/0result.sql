/*-----------------------------------------------------------
  Daily % change in trading volume per ticker
  Window: 01-Aug-2021 → 10-Aug-2021
-----------------------------------------------------------*/
WITH formatted_vol AS (   -- 1. convert “volume” text → numeric
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "volume" = '-'                          THEN 0
            WHEN RIGHT("volume", 1) = 'K'                THEN TRY_TO_NUMBER(REPLACE("volume", 'K', '')) * 1000
            WHEN RIGHT("volume", 1) = 'M'                THEN TRY_TO_NUMBER(REPLACE("volume", 'M', '')) * 1000000
            ELSE TRY_TO_NUMBER(REPLACE("volume", ',', ''))
        END                                             AS volume_num
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"
    WHERE "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
      AND "market_date" LIKE '%-08-2021'
),
prev_non_zero AS (        -- 2. find previous non-zero volume per ticker
    SELECT
        "ticker",
        "market_date",
        volume_num,
        LAST_VALUE(NULLIF(volume_num, 0)) IGNORE NULLS
            OVER (PARTITION BY "ticker"
                  ORDER BY TO_DATE("market_date", 'DD-MM-YYYY')
                  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_volume
    FROM formatted_vol
)
-- 3. calculate % change and present results
SELECT
    "ticker",
    TO_DATE("market_date", 'DD-MM-YYYY')                AS trade_date,
    volume_num,
    prev_volume                                         AS prev_non_zero_volume,
    CASE
        WHEN prev_volume > 0
             THEN ROUND( (volume_num - prev_volume) / prev_volume * 100 , 2)
        ELSE NULL
    END                                                 AS pct_change_volume
FROM prev_non_zero
ORDER BY "ticker", trade_date;