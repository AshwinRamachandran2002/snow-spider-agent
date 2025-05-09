WITH base_tx AS (
    SELECT
        LOWER("from_address")   AS "from_addr",
        LOWER("to_address")     AS "to_addr",
        TO_DECIMAL("value")     AS "value_wei",
        TO_DECIMAL(COALESCE("receipt_gas_used",0))                       AS "gas_used",
        TO_DECIMAL(
            COALESCE("receipt_effective_gas_price","gas_price",0)
        )                                                               AS "gas_price"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "block_timestamp" < 1630454400000000          -- 2021-09-01 00:00:00 UTC
      AND "receipt_status" = 1                          -- only successful txs
),
movements AS (
    /* debit sender: value transferred + fee paid */
    SELECT
        "from_addr"              AS "address",
        -1 * ( "value_wei"
               + ("gas_used" * "gas_price") )           AS "delta_wei"
    FROM base_tx
    WHERE "from_addr" IS NOT NULL

    UNION ALL

    /* credit receiver: value received */
    SELECT
        "to_addr"                AS "address",
        "value_wei"              AS "delta_wei"
    FROM base_tx
    WHERE "to_addr" IS NOT NULL
)
SELECT
    "address",
    SUM("delta_wei") AS "balance_wei"
FROM movements
GROUP BY "address"
ORDER BY "balance_wei" DESC NULLS LAST
LIMIT 10;