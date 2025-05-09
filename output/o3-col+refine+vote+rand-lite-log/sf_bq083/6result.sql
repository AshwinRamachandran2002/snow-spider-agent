WITH usdc_flows AS (
    /* --------------------------------------------------------------------
       Pull all 2023 Ethereum txs sent to the USDC contract whose `input`
       indicates either a mint (0x40c10f19…) or a burn (0x42966c68…).
       ------------------------------------------------------------------ */
    SELECT
        /* Convert micro-second epoch to DATE (UTC) */
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                         AS "date",

        /* ----------------------------------------------------------------
           Decode the amount that was minted (+) or burned (–).
             • mint : amount is the 2nd parameter  →  SUBSTRING(..,75,64)
             • burn : amount is the 1st parameter  →  SUBSTRING(..,11,64)
           Amount is in 6-decimals; divide by 1 000 000 to get USDC units.
           -------------------------------------------------------------- */
        CASE
            WHEN ILIKE("input", '0x40c10f19%') THEN
                 CAST(CONCAT('0x', LTRIM(SUBSTRING("input", 75, 64), '0')) AS FLOAT) / 1e6
            ELSE /* burn */
                -1 * CAST(CONCAT('0x', LTRIM(SUBSTRING("input", 11, 64), '0')) AS FLOAT) / 1e6
        END                                                                    AS delta_usdc
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'          -- USDC contract
      AND "block_timestamp" BETWEEN 1672531200000000                           -- 2023-01-01 00:00 UTC
                                     AND 1704067199000000                      -- 2023-12-31 23:59 UTC
      AND (
             ILIKE("input", '0x40c10f19%')  /* mint  */
          OR ILIKE("input", '0x42966c68%')  /* burn  */
          )
)

SELECT
    "date",
    /* Format the daily net change as USD (two decimals, sign in front) */
    TO_CHAR(SUM(delta_usdc), 'S$999,999,999,999,990.00') AS "Δ Total Market Value"
FROM usdc_flows
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;