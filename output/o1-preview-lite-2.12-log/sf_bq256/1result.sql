WITH most_active_address AS (
    SELECT t."from_address" AS "address"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < DATE_PART(EPOCH_SECOND, TIMESTAMP '2021-09-01 00:00:00') * 1000000
      AND t."hash" NOT IN (
          SELECT DISTINCT tr."transaction_hash"
          FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES" tr
          WHERE tr."trace_type" IN ('delegatecall', 'callcode', 'staticcall')
            AND tr."block_timestamp" < DATE_PART(EPOCH_SECOND, TIMESTAMP '2021-09-01 00:00:00') * 1000000
      )
    GROUP BY t."from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT balances."address" AS "Address",
       ROUND((SUM(balances."incoming") - SUM(balances."outgoing") - SUM(balances."gas_fee") + SUM(balances."mining_reward")) / POWER(10, 18), 4) AS "Final_Ether_Balance"
FROM (
    -- Incoming transfers
    SELECT t."to_address" AS "address", SUM(t."value") AS "incoming", 0 AS "outgoing", 0 AS "gas_fee", 0 AS "mining_reward"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t, most_active_address m
    WHERE t."to_address" = m."address"
      AND t."receipt_status" = 1
      AND t."block_timestamp" < DATE_PART(EPOCH_SECOND, TIMESTAMP '2021-09-01 00:00:00') * 1000000
    GROUP BY t."to_address"

    UNION ALL

    -- Outgoing transfers and gas fees
    SELECT t."from_address" AS "address", 0 AS "incoming", SUM(t."value") AS "outgoing", SUM(t."receipt_gas_used" * t."gas_price") AS "gas_fee", 0 AS "mining_reward"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" t, most_active_address m
    WHERE t."from_address" = m."address"
      AND t."receipt_status" = 1
      AND t."block_timestamp" < DATE_PART(EPOCH_SECOND, TIMESTAMP '2021-09-01 00:00:00') * 1000000
    GROUP BY t."from_address"

    UNION ALL

    -- Miner rewards
    SELECT b."miner" AS "address", 0 AS "incoming", 0 AS "outgoing", 0 AS "gas_fee", COUNT(*) * 2 * POWER(10, 18) AS "mining_reward"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."BLOCKS" b, most_active_address m
    WHERE b."miner" = m."address"
      AND b."timestamp" < DATE_PART(EPOCH_SECOND, TIMESTAMP '2021-09-01 00:00:00') * 1000000
    GROUP BY b."miner"
) AS balances
GROUP BY balances."address";