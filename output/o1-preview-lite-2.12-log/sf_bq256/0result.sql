WITH excluded_tx_hashes AS (
    SELECT DISTINCT "transaction_hash"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "call_type" IN ('delegatecall', 'callcode', 'staticcall')
      AND TO_TIMESTAMP("block_timestamp" / 1000000) < TO_TIMESTAMP('2021-09-01', 'YYYY-MM-DD')
),
filtered_transactions AS (
    SELECT *
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t
    WHERE t."receipt_status" = 1
      AND TO_TIMESTAMP(t."block_timestamp" / 1000000) < TO_TIMESTAMP('2021-09-01', 'YYYY-MM-DD')
      AND t."hash" NOT IN (SELECT "transaction_hash" FROM excluded_tx_hashes)
),
max_tx_address AS (
    SELECT "from_address"
    FROM (
        SELECT "from_address", COUNT(*) AS transaction_count
        FROM filtered_transactions
        GROUP BY "from_address"
        ORDER BY transaction_count DESC NULLS LAST
        LIMIT 1
    )
),
outgoing_transfers AS (
    SELECT SUM("value") AS total_sent
    FROM filtered_transactions t
    JOIN max_tx_address mta ON t."from_address" = mta."from_address"
),
incoming_transfers AS (
    SELECT SUM("value") AS total_received
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t
    JOIN max_tx_address mta ON t."to_address" = mta."from_address"
    WHERE t."receipt_status" = 1
      AND TO_TIMESTAMP(t."block_timestamp" / 1000000) < TO_TIMESTAMP('2021-09-01', 'YYYY-MM-DD')
),
gas_fees_paid AS (
    SELECT SUM(t."receipt_gas_used" * t."gas_price") AS total_gas_paid
    FROM filtered_transactions t
    JOIN max_tx_address mta ON t."from_address" = mta."from_address"
),
miner_rewards AS (
    SELECT SUM(
        CASE 
            WHEN b."number" < 4370000 THEN 5 * 1e18
            WHEN b."number" >= 4370000 AND b."number" < 7280000 THEN 3 * 1e18
            WHEN b."number" >= 7280000 THEN 2 * 1e18
            ELSE 0
        END
    ) AS total_miner_rewards_wei
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."BLOCKS" b
    JOIN max_tx_address mta ON b."miner" = mta."from_address"
    WHERE TO_TIMESTAMP(b."timestamp" / 1000000) < TO_TIMESTAMP('2021-09-01', 'YYYY-MM-DD')
)
SELECT 
    mta."from_address" AS "Address",
    ((COALESCE(it.total_received, 0) + COALESCE(mr.total_miner_rewards_wei, 0) - COALESCE(ot.total_sent, 0) - COALESCE(gf.total_gas_paid, 0)) / 1e18) AS "Final_Ether_Balance"
FROM max_tx_address mta
LEFT JOIN outgoing_transfers ot ON 1=1
LEFT JOIN incoming_transfers it ON 1=1
LEFT JOIN gas_fees_paid gf ON 1=1
LEFT JOIN miner_rewards mr ON 1=1;