/* Daily net market‑value change (mint – burn) of USDC in 2023 */
WITH usdc_activity AS (
    SELECT
        /* convert µs‑epoch to calendar date (UTC) */
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)                        AS "date",

        /* signed amount in full USDC: mint (+) ; burn (–) */
        CASE
            /* 0x40c10f19 ‑ mint(address,uint256) → amount starts at byte 75 */
            WHEN "input" LIKE '0x40c10f19%' THEN
                 TRY_TO_NUMBER(SUBSTR("input", 75, 64), 16) / 1000000

            /* 0x42966c68 ‑ burn(uint256)           → amount starts at byte 11 */
            WHEN "input" LIKE '0x42966c68%' THEN
                -TRY_TO_NUMBER(SUBSTR("input", 11, 64), 16) / 1000000
        END                                                                               AS amt
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'   -- USDC contract
      AND "block_timestamp" BETWEEN 1672531200000000                    -- 2023‑01‑01 00:00:00
                                 AND 1704067199999999                   -- 2023‑12‑31 23:59:59
      AND ("input" LIKE '0x40c10f19%' OR "input" LIKE '0x42966c68%')    -- mint or burn
)

SELECT
    "date",
    TO_CHAR(SUM(amt), 'FM$999,999,999,999,990.0000') AS net_market_value_change_usd
FROM usdc_activity
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;