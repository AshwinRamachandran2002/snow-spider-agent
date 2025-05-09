WITH tx AS (
    SELECT
        t."hash",
        t."block_number",
        t."from_address",
        COALESCE(t."to_address", t."receipt_contract_address")  AS "to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used",
        b."miner",
        t."block_timestamp"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC."TRANSACTIONS" t
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC."BLOCKS"       b
          ON t."block_number" = b."number"
    WHERE t."receipt_status" = 1
      AND TO_DATE( TO_TIMESTAMP_LTZ( t."block_timestamp" / 1e6) ) = '2016-10-14'
),
movements AS (
    /* debit: sender pays value + gas fee */
    SELECT
        "from_address"                                             AS address,
        - ( "value" + "gas_price" * "receipt_gas_used" )           AS delta
    FROM tx

    UNION ALL
    /* credit: recipient receives transferred value */
    SELECT
        "to_address"                                               AS address,
        "value"                                                    AS delta
    FROM tx
    WHERE "to_address" IS NOT NULL

    UNION ALL
    /* credit: miner receives gas fee */
    SELECT
        "miner"                                                    AS address,
        "gas_price" * "receipt_gas_used"                           AS delta
    FROM tx
),
net_changes AS (
    SELECT
        address,
        SUM(delta) AS net_change
    FROM movements
    GROUP BY address
)
SELECT
    MAX(net_change) AS max_net_change,
    MIN(net_change) AS min_net_change
FROM net_changes;