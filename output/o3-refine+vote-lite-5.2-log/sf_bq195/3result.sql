WITH eligible_tx AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value"                                              AS tx_value,
        COALESCE(t."receipt_gas_used",0)                       AS gas_used,
        COALESCE(t."receipt_effective_gas_price", t."gas_price",0) AS gas_price,
        COALESCE(tr.bad_call,0)                                AS bad_call
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    LEFT JOIN (
        /* flag transactions that have at least one trace with a call_type other than NULL/‘call’ */
        SELECT
            "transaction_hash",
            MAX(CASE WHEN "call_type" IS NOT NULL 
                      AND LOWER("call_type") <> 'call' 
                     THEN 1 ELSE 0 END)          AS bad_call
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
        GROUP BY "transaction_hash"
    ) tr
      ON tr."transaction_hash" = t."hash"
    WHERE
          t."receipt_status" = 1                                      -- successful tx
      AND t."block_timestamp" < 1630454400000000                      -- before 2021‑09‑01
      AND COALESCE(tr.bad_call,0) = 0                                 -- keep only allowed call types
),
addr_flows AS (
    /* debit sender: value + gas ; credit receiver: value */
    SELECT
        "from_address"             AS address,
        -1 * (tx_value + gas_used * gas_price)     AS amount
    FROM eligible_tx
    UNION ALL
    SELECT
        "to_address"               AS address,
        tx_value                                   AS amount
    FROM eligible_tx
    WHERE "to_address" IS NOT NULL
),
balances AS (
    SELECT
        address,
        SUM(amount) AS balance_wei
    FROM addr_flows
    GROUP BY address
)
SELECT
    address,
    balance_wei
FROM balances
ORDER BY balance_wei DESC NULLS LAST, address
LIMIT 10;