WITH valid_tx AS (
    SELECT
        tx."hash",
        tx."from_address",
        tx."to_address",
        tx."value",
        tx."receipt_gas_used",
        COALESCE(tx."receipt_effective_gas_price",tx."gas_price") AS "effective_gas_price"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS AS tx
    WHERE
        tx."block_timestamp" < 1630454400000000 -- 2021‑09‑01 00:00:00 UTC in µs
        AND tx."receipt_status" = 1                                         -- successful
        AND NOT EXISTS (                                                    -- exclude delegate/callcode/staticcall
              SELECT 1
              FROM CRYPTO.CRYPTO_ETHEREUM.TRACES AS tr
              WHERE  tr."transaction_hash" = tx."hash"
                AND  tr."trace_type" IN ('delegatecall','callcode','staticcall')
        )
),
top_sender AS (   -- address with the most successful txs before 1‑Sep‑2021
    SELECT
        "from_address" AS "address"
    FROM valid_tx
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
balance_components AS (   -- aggregate inflows, outflows, and gas cost
    SELECT
        SUM(CASE WHEN v."to_address"   = ts."address" THEN v."value"                                                    ELSE 0 END) AS "inflow_wei",
        SUM(CASE WHEN v."from_address" = ts."address" THEN v."value"                                                    ELSE 0 END) AS "outflow_wei",
        SUM(CASE WHEN v."from_address" = ts."address" THEN v."receipt_gas_used"*v."effective_gas_price"                ELSE 0 END) AS "gas_wei"
    FROM valid_tx AS v
    CROSS JOIN top_sender AS ts
)
SELECT
    ( "inflow_wei" - "outflow_wei" - "gas_wei" ) / 1e18      AS "final_balance_in_ether"
FROM balance_components;