WITH eligible_tx AS (   -- successful txs before 1-Sep-2021 whose root trace has no call_type or call_type='call'
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."block_number",
        (t."receipt_gas_used" * t."receipt_effective_gas_price") AS gas_fee
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS            AS t
    INNER JOIN (                                        -- root traces that qualify
        SELECT DISTINCT "transaction_hash"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
        WHERE ("call_type" IS NULL OR "call_type" = 'call')
          AND "status" = 1
          AND "block_timestamp" < 1630454400000000      -- 2021-09-01 UTC
    )                                                  AS r
        ON r."transaction_hash" = t."hash"
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000        -- 2021-09-01 UTC
),
balance_changes AS (                                   -- three legs: sender, recipient, miner
    SELECT
        et."from_address"         AS address,
        -(et."value" + et.gas_fee) AS change
    FROM eligible_tx et

    UNION ALL
    SELECT
        et."to_address"           AS address,
        et."value"                AS change
    FROM eligible_tx et

    UNION ALL
    SELECT
        b."miner"                 AS address,
        et.gas_fee                AS change
    FROM eligible_tx et
    JOIN CRYPTO.CRYPTO_ETHEREUM.BLOCKS AS b
      ON b."number" = et."block_number"
)
SELECT
    address,
    SUM(change) AS balance
FROM balance_changes
WHERE address IS NOT NULL
GROUP BY address
ORDER BY balance DESC NULLS LAST
LIMIT 10;