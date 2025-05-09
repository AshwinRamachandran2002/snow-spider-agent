/*--------------------------------------------------------------------
  Daily %-change in trading volume for each crypto ticker
  from 01-Aug-2021 to 10-Aug-2021
--------------------------------------------------------------------*/
WITH cleaned AS (   /* convert “volume” text → numeric value */
    SELECT
        "ticker",
        TO_DATE("market_date",'DD-MM-YYYY')           AS "market_date",
        CASE
            WHEN "volume" IS NULL OR "volume" = '-'            THEN 0
            WHEN UPPER("volume") LIKE '%K'                     THEN TO_NUMBER(REGEXP_SUBSTR("volume",'^[0-9.]+'))*1000
            WHEN UPPER("volume") LIKE '%M'                     THEN TO_NUMBER(REGEXP_SUBSTR("volume",'^[0-9.]+'))*1000000
            /* volumes already expressed as plain numbers (rare) */
            ELSE TO_NUMBER(REGEXP_SUBSTR("volume",'^[0-9.]+'))
        END                                                   AS "volume_numeric"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES
    WHERE "market_date" BETWEEN '01-08-2021' AND '10-08-2021'
)
SELECT
    "ticker",
    TO_CHAR("market_date",'DD-08-2021')       AS "market_date",      -- keep original text format
    "volume_numeric",
    /* previous non-zero volume within the same ticker */
    CASE
        WHEN prev_non_zero_volume IS NULL OR prev_non_zero_volume = 0
             THEN NULL
        ELSE ROUND( ( "volume_numeric" - prev_non_zero_volume )
                    / prev_non_zero_volume * 100 , 4)
    END                                           AS "pct_change_volume"
FROM (
    SELECT
        c.*,
        /* last non-zero volume observed BEFORE current row */
        LAST_VALUE( NULLIF("volume_numeric",0) ) 
              IGNORE NULLS
              OVER (PARTITION BY "ticker"
                    ORDER BY "market_date"
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
              AS prev_non_zero_volume
    FROM cleaned c
)
ORDER BY "ticker","market_date";