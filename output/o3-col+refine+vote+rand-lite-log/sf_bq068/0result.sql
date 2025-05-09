/* max & min final balances per address type for Bitcoin-Cash
   (2014-03-01  –  2014-04-01) using double-entry bookkeeping      */
WITH
-- blocks that belong to the requested month bucket
blocks_in_window AS (
    SELECT  "number"
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.BLOCKS
    WHERE   "timestamp_month" BETWEEN '2014-03-01' AND '2014-04-01'
),

/* credits (transaction outputs) */
credit AS (
    SELECT  f.VALUE::STRING            AS "address",
            SUM(o."value")             AS "credit"
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS            o
    JOIN    blocks_in_window                           b  ON b."number" = o."block_number"
            , LATERAL FLATTEN(INPUT => o."addresses")    f
    GROUP BY 1
),

/* debits (transaction inputs) */
debit AS (
    SELECT  f.VALUE::STRING            AS "address",
            SUM(i."value")             AS "debit"
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS             i
    JOIN    blocks_in_window                           b  ON b."number" = i."block_number"
            , LATERAL FLATTEN(INPUT => i."addresses")    f
    GROUP BY 1
),

/* net balance per address = credit – debit */
balance AS (
    SELECT  COALESCE(c."address", d."address")                       AS "address",
            COALESCE(c."credit", 0) - COALESCE(d."debit", 0)        AS "final_balance"
    FROM    credit  c
    FULL JOIN debit   d USING ("address")
),

/* representative address type (derived from OUTPUTS) */
addr_type AS (
    SELECT  f.VALUE::STRING            AS "address",
            MIN(o."type")              AS "addr_type"
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS            o
    JOIN    blocks_in_window                           b  ON b."number" = o."block_number"
            , LATERAL FLATTEN(INPUT => o."addresses")    f
    GROUP BY 1
)

/* final aggregation: max & min ending balances by address type */
SELECT  a."addr_type",
        MAX(b."final_balance")  AS "max_final_balance",
        MIN(b."final_balance")  AS "min_final_balance"
FROM    balance     b
JOIN    addr_type   a  USING ("address")
GROUP BY a."addr_type"
ORDER BY a."addr_type";