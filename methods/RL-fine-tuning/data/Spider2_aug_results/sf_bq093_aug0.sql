-- Task: Calculate the maximum and minimum net changes in balances for Ethereum Classic addresses on October 14, 2016. The net change for each address is computed by summing:
-- - Debits: Values sent to addresses ("to_address") in successful transactions (where "status" = 1), excluding internal calls (where "call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL) from the TRACES table.
-- - Credits: Negative values sent from addresses ("from_address") in successful transactions, excluding internal calls, from the TRACES table.
-- - Transaction fees for miners: Sum of "receipt_gas_used" multiplied by "gas_price" for miners (positive values), grouped by miner addresses from the TRANSACTIONS and BLOCKS tables.
-- - Transaction fees for senders: Negative sum of "receipt_gas_used" multiplied by "gas_price" for senders (negative values) from the TRANSACTIONS table.
-- Only data from October 14, 2016, based on the "block_timestamp" field, is considered. Finally, find the maximum and minimum net changes among all addresses.

WITH double_entry_book AS (
    -- Debits
    SELECT 
        "to_address" AS "address", 
        "value" AS "value"
    FROM 
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE 
        "to_address" IS NOT NULL
        AND "status" = 1
        AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
        AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) = '2016-10-14'

    UNION ALL
    
    -- Credits
    SELECT 
        "from_address" AS "address", 
        - "value" AS "value"
    FROM 
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE 
        "from_address" IS NOT NULL
        AND "status" = 1
        AND ("call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') OR "call_type" IS NULL)
        AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) = '2016-10-14'

    UNION ALL

    -- Transaction Fees Debits (Miners)
    SELECT 
        "miner" AS "address", 
        SUM(CAST("receipt_gas_used" AS NUMERIC) * CAST("gas_price" AS NUMERIC)) AS "value"
    FROM 
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS AS "transactions"
    JOIN 
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS AS "blocks" 
        ON "blocks"."number" = "transactions"."block_number"
    WHERE 
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) = '2016-10-14'
    GROUP BY 
        "blocks"."miner"

    UNION ALL
    
    -- Transaction Fees Credits (Senders)
    SELECT 
        "from_address" AS "address", 
        -(CAST("receipt_gas_used" AS NUMERIC) * CAST("gas_price" AS NUMERIC)) AS "value"
    FROM 
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
    WHERE 
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) = '2016-10-14'
),
net_changes AS (
    SELECT 
        "address",
        SUM("value") AS "net_change"
    FROM 
        double_entry_book
    GROUP BY 
        "address"
)
SELECT 
    MAX("net_change") AS "max_net_change",
    MIN("net_change") AS "min_net_change"
FROM
    net_changes;