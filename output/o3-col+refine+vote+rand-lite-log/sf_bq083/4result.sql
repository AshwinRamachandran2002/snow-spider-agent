/*  Daily change in the market value of USDC (in USD, millions) for 2023  */
WITH usdc_transactions AS (
    SELECT
        /* Convert micro-second epoch to DATE (UTC) */
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                    AS "tx_date",

        /* + amount for mint, – amount for burn (both scaled to actual USDC) */
        CASE
            /* Mint: selector 0x40c10f19…, amount is bytes 75-138 */
            WHEN "input" ILIKE '0x40c10f19%' THEN
                 TRY_TO_NUMBER(LTRIM(SUBSTR("input", 75, 64), '0'), 16) / 1e6
            /* Burn: selector 0x42966c68…, amount is bytes 11-74 */
            WHEN "input" ILIKE '0x42966c68%' THEN
               -TRY_TO_NUMBER(LTRIM(SUBSTR("input", 11, 64), '0'), 16) / 1e6
        END                                                              AS "delta_usdc"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'          -- USDC contract
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')          -- mint or burn
      AND YEAR(TO_TIMESTAMP("block_timestamp" / 1e6)) = 2023                   -- year 2023 only
)

SELECT
  "tx_date",
  /* Format the net daily change as a currency string */
  TO_CHAR(
      SUM("delta_usdc"),
      'FM$999,999,999,999,990D00'
  ) AS "Δ Total Market Value"
FROM usdc_transactions
GROUP BY "tx_date"
ORDER BY "tx_date" DESC NULLS LAST;