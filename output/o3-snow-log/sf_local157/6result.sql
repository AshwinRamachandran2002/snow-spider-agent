/*-------------------------------------------------------------
 * Daily % change in trading volume (1-10 Aug 2021)
 *   – Converts “volume” strings to numbers (K → ×1 000, M → ×1 000 000, ‘-’ → 0)
 *   – Uses the most-recent NON-ZERO volume as the prior-day value
 *   – Results ordered by ticker and date
 *------------------------------------------------------------*/
WITH base AS (
    SELECT
        "ticker",
        TO_DATE("market_date",'DD-MM-YYYY')        AS "market_date",
        TRIM("volume")                             AS "vol_raw"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES
    WHERE TO_DATE("market_date",'DD-MM-YYYY')
          BETWEEN '2021-08-01' AND '2021-08-10'
),
converted AS (
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "vol_raw" = '-' THEN 0
            WHEN RIGHT("vol_raw",1) ILIKE 'K'
                 THEN TRY_TO_NUMBER(REPLACE("vol_raw",'K','')) * 1000
            WHEN RIGHT("vol_raw",1) ILIKE 'M'
                 THEN TRY_TO_NUMBER(REPLACE("vol_raw",'M','')) * 1000000
            ELSE TRY_TO_NUMBER("vol_raw")
        END                                         AS "volume_numeric"
    FROM base
),
with_prev AS (
    SELECT
        "ticker",
        "market_date",
        "volume_numeric",
        /* bring forward the last non-zero volume */
        LAG(NULLIF("volume_numeric",0)) 
            IGNORE NULLS 
            OVER (PARTITION BY "ticker" ORDER BY "market_date") AS "prev_non_zero_vol"
    FROM converted
)
SELECT
    "ticker",
    TO_CHAR("market_date",'DD-MM-YYYY')            AS "market_date",
    "volume_numeric"                               AS "current_volume",
    "prev_non_zero_vol"                            AS "previous_non_zero_volume",
    CASE
        WHEN "prev_non_zero_vol" IS NULL THEN NULL
        ELSE ROUND( ( "volume_numeric" - "prev_non_zero_vol" )
                    / "prev_non_zero_vol" * 100 , 4)
    END                                            AS "pct_change_volume"
FROM with_prev
ORDER BY "ticker", "market_date";