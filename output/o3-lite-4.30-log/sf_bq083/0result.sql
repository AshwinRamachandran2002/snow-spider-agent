WITH per_tx AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("block_timestamp" / 1000000),
            'YYYY-MM-DD'
        ) AS "date",
        CASE
            WHEN "input" LIKE '0x40c10f19%' THEN 1      -- mint  (+)
            ELSE -1                                     -- burn  (‑)
        END
        *
        COALESCE(                                      -- hex → decimal, safe
            TRY_TO_NUMBER(
                LTRIM(
                    SUBSTR(
                        "input",
                        CASE WHEN "input" LIKE '0x40c10f19%' THEN 75 ELSE 11 END,
                        64
                    ),
                    '0'
                ),
                16
            ),
            0
        ) / 1000000                                    -- scale from micro‑USDC to USDC
        AS amount_usd
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND ("input" LIKE '0x40c10f19%' OR "input" LIKE '0x42966c68%')
      AND "block_timestamp" BETWEEN 1672444800000000     -- 2023‑01‑01 00:00:00 UTC
                               AND 1704067199000000     -- 2023‑12‑31 23:59:59 UTC
)
SELECT
    "date",
    TO_CHAR(
        SUM(amount_usd),
        'FM$999,999,999,999,999,999,990.0000'
    ) AS net_market_value_change_usd
FROM per_tx
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;