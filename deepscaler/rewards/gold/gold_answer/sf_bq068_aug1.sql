-- Task: Using double-entry bookkeeping principles by treating transaction inputs as debits (negative values) and outputs as credits (positive values) for all Bitcoin Cash transactions between '2014-03-01' and '2014-04-01', create a double-entry book listing addresses, types, and values of all debits and credits.

WITH double_entry_book AS (
    -- debits
    SELECT
        ARRAY_TO_STRING("inputs".value:addresses, ',') AS "address",  -- Concatenate addresses
        "inputs".value:type AS "type",
        - "inputs".value:value AS "value"  -- Negative value for debits
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.TRANSACTIONS,
         LATERAL FLATTEN(INPUT => "inputs") AS "inputs"
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) >= '2014-03-01' 
      AND TO_TIMESTAMP("block_timestamp" / 1000000) < '2014-04-01'

    UNION ALL

    -- credits
    SELECT
        ARRAY_TO_STRING("outputs".value:addresses, ',') AS "address",  -- Concatenate addresses
        "outputs".value:type AS "type",
        "outputs".value:value AS "value"  -- Positive value for credits
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.TRANSACTIONS, 
         LATERAL FLATTEN(INPUT => "outputs") AS "outputs"
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000) >= '2014-03-01' 
      AND TO_TIMESTAMP("block_timestamp" / 1000000) < '2014-04-01'
)
SELECT * FROM double_entry_book;