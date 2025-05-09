WITH tx AS (
    SELECT
        /* calendar date (UTC) */
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS day_utc,

        /* +1 for mint, -1 for burn */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN 1
            ELSE -1
        END AS sign,

        /* 32‑byte amount slot (hex, no 0x) */
        CASE
            /* mint(address,uint256) → amount is the 2nd slot */
            WHEN "input" ILIKE '0x40c10f19%' THEN SUBSTRING("input", 75, 64)
            /* burn(uint256)         → amount is the 1st slot */
            ELSE SUBSTRING("input", 11, 64)
        END AS amt_hex
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'      -- USDC contract
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')     -- mint / burn
      AND "block_timestamp" BETWEEN 1672531200000000                       -- 2023‑01‑01 00:00 UTC
                                AND 1704067199000000                       -- 2023‑12‑31 23:59 UTC
), amounts AS (
    /* convert hex to decimal, apply sign, scale from µUSDC → USDC */
    SELECT
        day_utc,
        sign * (TRY_TO_NUMBER(amt_hex, 16) / 1000000) AS delta_usdc
    FROM tx
)
SELECT
    TO_CHAR(day_utc, 'YYYY-MM-DD')                        AS "date",
    TO_CHAR(SUM(delta_usdc),
            'FM$999,999,999,999,990D0000')                AS "net_market_value_change_usd"
FROM amounts
GROUP BY day_utc
ORDER BY day_utc DESC NULLS LAST;