WITH net_changes AS (
    SELECT "address", SUM("net_balance_change") AS "net_balance_change"
    FROM (
        SELECT "from_address" AS "address", -("value" + ("gas_price" * "receipt_gas_used")) AS "net_balance_change"
        FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
        WHERE "block_timestamp" >= 1476403200000000 AND "block_timestamp" < 1476489600000000

        UNION ALL

        SELECT "to_address" AS "address", "value" AS "net_balance_change"
        FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS
        WHERE "block_timestamp" >= 1476403200000000 AND "block_timestamp" < 1476489600000000

        UNION ALL

        SELECT "from_address" AS "address", - "value" AS "net_balance_change"
        FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
        WHERE "block_timestamp" >= 1476403200000000 AND "block_timestamp" < 1476489600000000
          AND ("call_type" IS NULL OR "call_type" NOT IN ('delegatecall', 'callcode', 'staticcall'))

        UNION ALL

        SELECT "to_address" AS "address", "value" AS "net_balance_change"
        FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
        WHERE "block_timestamp" >= 1476403200000000 AND "block_timestamp" < 1476489600000000
          AND ("call_type" IS NULL OR "call_type" NOT IN ('delegatecall', 'callcode', 'staticcall'))
    ) AS "balance_changes"
    GROUP BY "address"
),
max_change AS (
    SELECT "address" AS "Address_with_Max_Net_Change", ROUND("net_balance_change", 4) AS "Maximum_Net_Change"
    FROM net_changes
    ORDER BY "net_balance_change" DESC NULLS LAST
    LIMIT 1
),
min_change AS (
    SELECT "address" AS "Address_with_Min_Net_Change", ROUND("net_balance_change", 4) AS "Minimum_Net_Change"
    FROM net_changes
    ORDER BY "net_balance_change" ASC NULLS LAST
    LIMIT 1
)
SELECT
    max_change."Address_with_Max_Net_Change",
    max_change."Maximum_Net_Change",
    min_change."Address_with_Min_Net_Change",
    min_change."Minimum_Net_Change"
FROM max_change
CROSS JOIN min_change;