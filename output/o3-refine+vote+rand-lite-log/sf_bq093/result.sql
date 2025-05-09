WITH "TX_DAY" AS (
    SELECT
        tx."hash",
        tx."from_address",
        tx."to_address",
        /* values in ETC tables are stored as strings – cast to numeric */
        TO_DECIMAL(tx."value")                                    AS "value",
        TO_DECIMAL(tx."gas_price")                                AS "gas_price",
        TO_DECIMAL(tx."receipt_gas_used")                         AS "gas_used",
        b."miner"
    FROM
        CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS"  tx
        JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"   b
              ON tx."block_hash" = b."hash"
    WHERE
        tx."receipt_status" = 1                                           -- successful only
        AND DATE_TRUNC(
                'DAY',
                TO_TIMESTAMP(tx."block_timestamp" / 1000000)
            ) = '2016-10-14'                                             -- 14‑Oct‑2016 UTC
), "DELTA_ROWS" AS (
    /* 1) sender debits: amount sent + gas fee */
    SELECT
        "from_address"                           AS "address",
        -("value") - ("gas_price" * "gas_used")  AS "delta"
    FROM "TX_DAY"

    UNION ALL
    /* 2) receiver credits: amount received */
    SELECT
        "to_address"         AS "address",
        "value"              AS "delta"
    FROM "TX_DAY"
    WHERE "to_address" IS NOT NULL

    UNION ALL
    /* 3) miner credits: gas fee received */
    SELECT
        "miner"                              AS "address",
        ("gas_price" * "gas_used")           AS "delta"
    FROM "TX_DAY"
), "NET_CHANGES" AS (
    SELECT
        "address",
        SUM("delta") AS "net_change"
    FROM "DELTA_ROWS"
    GROUP BY "address"
)
SELECT
    MAX("net_change") AS "max_net_balance_change",
    MIN("net_change") AS "min_net_balance_change"
FROM "NET_CHANGES";