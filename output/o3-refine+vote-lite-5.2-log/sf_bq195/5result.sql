WITH
/* 1.  Identify transactions that contain at least one successful trace whose
       call_type is something other than NULL/‘call’.  These transactions must
       be discarded. */
"invalid_tx" AS (
    SELECT DISTINCT
           "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "status" = 1
      AND  "call_type" IS NOT NULL
      AND  LOWER("call_type") <> 'call'
),
/* 2.  Keep successful transactions prior to 2021‑09‑01 that are **not**
       in the set above.                                               */
"good_tx" AS (
    SELECT  t."hash",
            t."from_address"  AS "sender",
            t."to_address"    AS "receiver",
            t."value",
            t."gas_price",
            t."receipt_gas_used",
            (t."gas_price" * t."receipt_gas_used") AS "gas_fee"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    WHERE   t."block_timestamp" < 1630454400000000      -- 2021‑09‑01 UTC
      AND   t."receipt_status" = 1                      -- successful tx
      AND   t."hash" NOT IN (SELECT "transaction_hash" FROM "invalid_tx")
),
/* 3.  Translate each transaction into balance‑changing rows
       (+value to receiver, –(value+gas) from sender).                 */
"balance_changes" AS (
    SELECT  "receiver"               AS "address",
            CAST("value" AS DECIMAL) AS "delta"
    FROM    "good_tx"
    WHERE   "receiver" IS NOT NULL

    UNION ALL

    SELECT  "sender"                                            AS "address",
           -CAST(("value" + "gas_fee") AS DECIMAL)              AS "delta"
    FROM    "good_tx"
    WHERE   "sender" IS NOT NULL
)
/* 4.  Aggregate and list the top 10 addresses by resulting balance.   */
SELECT      "address",
            SUM("delta") AS "net_balance"
FROM        "balance_changes"
GROUP BY    "address"
ORDER BY    "net_balance" DESC NULLS LAST
LIMIT 10;