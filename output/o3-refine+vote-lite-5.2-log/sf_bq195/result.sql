WITH
/* --------------------------------------------------------------------------
   1.  Keep only successful transactions prior to 2021‑09‑01
       and be sure they have   – no trace with a non‑NULL, non‑'call' call_type
   -------------------------------------------------------------------------- */
eligible_txs AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."receipt_gas_used",
        COALESCE(t."receipt_effective_gas_price", t."gas_price")     AS "gas_price_effective",
        t."block_hash"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"        t
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000               -- 2021‑09‑01 00:00:00 UTC
      AND t."hash" NOT IN (
              SELECT DISTINCT tr."transaction_hash"
              FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES" tr
              WHERE  tr."call_type" IS NOT NULL
                AND  LOWER(tr."call_type") <> 'call'
      )
),
/* --------------------------------------------------------------------------
   2.  Add miner address to every eligible transaction
   -------------------------------------------------------------------------- */
tx_with_miner AS (
    SELECT
        e.*,
        b."miner"                                     AS miner_address
    FROM eligible_txs e
    JOIN CRYPTO.CRYPTO_ETHEREUM."BLOCKS" b
          ON b."hash" = e."block_hash"
),
/* --------------------------------------------------------------------------
   3.  Convert each transaction into balance‑change rows
       (sender – value – gas , receiver + value , miner + gas)
   -------------------------------------------------------------------------- */
balance_changes AS (
    SELECT
        LOWER("from_address") AS address,
        -1 * (e."value" + e."receipt_gas_used" * e."gas_price_effective") AS amount
    FROM tx_with_miner e
    WHERE e."from_address" IS NOT NULL

    UNION ALL
    SELECT
        LOWER("to_address")   AS address,
        e."value"                                            AS amount
    FROM tx_with_miner e
    WHERE e."to_address"   IS NOT NULL

    UNION ALL
    SELECT
        LOWER(miner_address) AS address,
        e."receipt_gas_used" * e."gas_price_effective"       AS amount
    FROM tx_with_miner e
    WHERE miner_address IS NOT NULL
)
/* --------------------------------------------------------------------------
   4.  Aggregate and return the richest 10 addresses
   -------------------------------------------------------------------------- */
SELECT
    address,
    SUM(amount) AS balance
FROM balance_changes
GROUP BY address
ORDER BY balance DESC NULLS LAST
LIMIT 10;