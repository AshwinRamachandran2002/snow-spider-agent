WITH parsed_volumes AS (
    /* 1) Keep only 01-Aug-2021 → 10-Aug-2021
       2) Convert the text “volume” column to a pure numeric value           */
    SELECT
        "ticker"                                              AS ticker,          -- make subsequent references easy
        TO_DATE("market_date", 'DD-MM-YYYY')                  AS market_dt,
        CASE
            WHEN "volume" = '-'                 THEN 0
            WHEN UPPER("volume") LIKE '%K'      THEN TRY_TO_NUMBER(REPLACE(UPPER("volume"), 'K', '')) * 1000
            WHEN UPPER("volume") LIKE '%M'      THEN TRY_TO_NUMBER(REPLACE(UPPER("volume"), 'M', '')) * 1000000
            ELSE TRY_TO_NUMBER("volume")
        END                                                   AS volume_val
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"
    WHERE TO_DATE("market_date", 'DD-MM-YYYY')
          BETWEEN '2021-08-01' AND '2021-08-10'
),
with_prev_non_zero AS (
    /* Fetch the most-recent non-zero volume that precedes the current row */
    SELECT
        ticker,
        market_dt,
        volume_val,
        LAST_VALUE( CASE WHEN volume_val = 0 THEN NULL ELSE volume_val END )
        IGNORE NULLS
        OVER (
            PARTITION BY ticker
            ORDER BY market_dt
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        )                                   AS prev_non_zero_volume
    FROM parsed_volumes
)
SELECT
    ticker,
    TO_CHAR(market_dt, 'DD-MM-YYYY')        AS market_date,
    volume_val                              AS volume,
    CASE
        WHEN prev_non_zero_volume IS NULL 
             OR prev_non_zero_volume = 0    THEN NULL
        ELSE ROUND( (volume_val - prev_non_zero_volume)
                    / prev_non_zero_volume * 100 , 4)
    END                                     AS pct_change_volume
FROM with_prev_non_zero
ORDER BY ticker,
         market_dt;