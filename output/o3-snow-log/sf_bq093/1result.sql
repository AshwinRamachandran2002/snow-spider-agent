WITH tx AS (
    /* All successful Ethereum-Classic transactions included in blocks
       mined on 14-Oct-2016 (timestamps are stored in µs) */
    SELECT
        t."block_number",
        t."from_address",
        t."to_address",
        t."value",
        t."gas_price",
        t."receipt_gas_used"
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRANSACTIONS  t
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS        b
      ON b."number" = t."block_number"
    WHERE t."receipt_status" = 1
      AND b."timestamp" >= 1476403200000000      -- 2016-10-14 00:00:00 UTC
      AND b."timestamp" <  1476489600000000      -- 2016-10-15 00:00:00 UTC
),
/* debits paid by senders (value + gas fee) */
sender_debits AS (
    SELECT
        "from_address"                         AS addr,
        SUM("value" + ("gas_price" * "receipt_gas_used"))  AS debit
    FROM tx
    WHERE "from_address" IS NOT NULL
    GROUP BY addr
),
/* credits received by normal recipients (value) */
receiver_credits AS (
    SELECT
        "to_address"   AS addr,
        SUM("value")   AS credit
    FROM tx
    WHERE "to_address" IS NOT NULL
    GROUP BY addr
),
/* gas-fee credits earned by block miners */
miner_credits AS (
    SELECT
        b."miner"                              AS addr,
        SUM(t."gas_price" * t."receipt_gas_used") AS credit
    FROM tx  t
    JOIN CRYPTO.CRYPTO_ETHEREUM_CLASSIC.BLOCKS b
      ON b."number" = t."block_number"
    WHERE b."miner" IS NOT NULL
    GROUP BY addr
),
/* union of all addresses that moved balance */
all_addr AS (
    SELECT addr FROM sender_debits
    UNION
    SELECT addr FROM receiver_credits
    UNION
    SELECT addr FROM miner_credits
),
/* net balance change per address */
net_changes AS (
    SELECT
        a.addr,
        COALESCE(rc.credit, 0)            /* incoming transfers                */
      + COALESCE(mc.credit, 0)            /* miner gas rewards                 */
      - COALESCE(sd.debit , 0)            /* outgoing value  + sender gas fee  */
        AS net_change
    FROM all_addr           a
    LEFT JOIN receiver_credits rc USING (addr)
    LEFT JOIN miner_credits   mc USING (addr)
    LEFT JOIN sender_debits   sd USING (addr)
)
/* final maximum and minimum net balance changes */
SELECT 'max' AS metric, MAX(net_change) AS net_balance_change
FROM   net_changes
UNION ALL
SELECT 'min' AS metric, MIN(net_change) AS net_balance_change
FROM   net_changes
ORDER  BY metric;