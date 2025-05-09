WITH txs AS (   
    SELECT
        /* convert micro‑seconds epoch to UTC date                       */
        TO_DATE( TO_TIMESTAMP("block_timestamp" / 1e6) )                         AS "date",
        
        /* +1 for mint, ‑1 for burn                                        */
        CASE 
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN  1 
            ELSE                                           -1 
        END                                                                      AS "sign",
        
        /* 64‑hex‑char amount slot                                           */
        CASE 
            WHEN LOWER("input") LIKE '0x40c10f19%' 
                 THEN SUBSTR("input", 75, 64)          -- mint
            ELSE      SUBSTR("input", 11, 64)          -- burn
        END                                                                      AS "amount_hex"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'            -- USDC
      AND "block_timestamp" BETWEEN 1672531200000000                              -- 2023‑01‑01 00:00:00
                                AND 1704067199000000                              -- 2023‑12‑31 23:59:59
      AND (  LOWER("input") LIKE '0x40c10f19%'    -- mint
          OR LOWER("input") LIKE '0x42966c68%' )  -- burn
), parsed AS (
    SELECT
        "date",
        /* hex → number (TRY_… avoids conversion errors), scale (6‑decimals)     */
        "sign" * ( COALESCE(TRY_TO_NUMBER("amount_hex", 16), 0) / 1e6 )  AS delta_usdc
    FROM txs
)
SELECT
    "date",
    TO_CHAR( SUM(delta_usdc), 'FM$999,999,999,999,999,990.00' )          AS "Δ Total Market Value"
FROM parsed
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;