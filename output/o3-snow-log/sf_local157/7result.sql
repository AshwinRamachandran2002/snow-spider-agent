/* Daily %-change in trading volume per ticker
   – Aug-01 → Aug-10 2021
   – “K” → ×1 000, “M” → ×1 000 000, “-” → 0
   – previous volume skips any zero values                        */

WITH volumes AS (   -- convert text volumes to pure numbers
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "volume" ILIKE '%K' THEN TRY_TO_NUMBER(REPLACE("volume",'K','')) * 1000
            WHEN "volume" ILIKE '%M' THEN TRY_TO_NUMBER(REPLACE("volume",'M','')) * 1000000
            WHEN "volume" = '-'       THEN 0
            ELSE TRY_TO_NUMBER("volume")
        END                              AS vol_numeric
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"
),
lagged AS (        -- grab the previous non-zero volume per ticker
    SELECT
        "ticker",
        "market_date",
        vol_numeric,
        LAG(NULLIF(vol_numeric,0)) IGNORE NULLS
            OVER (PARTITION BY "ticker"
                  ORDER BY TO_DATE("market_date",'DD-MM-YYYY'))  AS prev_non_zero_vol
    FROM volumes
)
SELECT
    "ticker",
    "market_date",
    vol_numeric                                                     AS volume_numeric,
    ROUND(100 * (vol_numeric - prev_non_zero_vol) / prev_non_zero_vol, 4)
                                                                    AS pct_change_vol
FROM lagged
WHERE TO_DATE("market_date",'DD-MM-YYYY') BETWEEN DATE '2021-08-01' AND DATE '2021-08-10'
  AND prev_non_zero_vol IS NOT NULL
ORDER BY "ticker", TO_DATE("market_date",'DD-MM-YYYY');