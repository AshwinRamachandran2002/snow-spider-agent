WITH parsed AS (
    /* 1. Convert the raw “volume” text into a pure numeric value          */
    SELECT
        "ticker",
        "market_date",
        CASE
            WHEN "volume" ILIKE '%K'      THEN TO_NUMBER(REPLACE("volume", 'K', '')) * 1000      -- thousands
            WHEN "volume" ILIKE '%M'      THEN TO_NUMBER(REPLACE("volume", 'M', '')) * 1000000   -- millions
            WHEN "volume" = '-'           THEN 0                                                -- dash → zero
            ELSE TO_NUMBER("volume")                                                             -- already numeric
        END AS "volume_num"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_PRICES"
    WHERE "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
), lagged AS (
    /* 2. Fetch the previous non-zero volume per ticker (IGNORE NULLS)     */
    SELECT
        *,
        LAG( NULLIF("volume_num", 0) ) 
            IGNORE NULLS
            OVER (PARTITION BY "ticker"
                  ORDER BY TO_DATE("market_date", 'DD-MM-YYYY')) AS "prev_volume"
    FROM parsed
)
SELECT
    "ticker",
    "market_date",
    ROUND( ( ("volume_num" - "prev_volume") / "prev_volume" ) * 100 , 2 )  AS "pct_change_volume"
FROM lagged
WHERE "prev_volume" IS NOT NULL                 -- ensures a valid prior non-zero volume
ORDER BY
    "ticker",
    TO_DATE("market_date", 'DD-MM-YYYY');