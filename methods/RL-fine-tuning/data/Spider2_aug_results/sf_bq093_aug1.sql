-- Task: For each address, calculate the net change in balance on October 14, 2016, by summing debits and credits, excluding internal calls, and only considering successful transactions. Limit the results to 100 addresses.
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

)
SELECT 
    "address",
    SUM("value") AS "net_change"
FROM 
    double_entry_book
GROUP BY 
    "address"
LIMIT 100;