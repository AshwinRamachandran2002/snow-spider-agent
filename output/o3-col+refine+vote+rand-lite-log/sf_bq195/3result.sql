WITH
/* 1.  Transactions that have at least one successful trace
       whose call_type is NULL or 'call', and occur before 1-Sep-2021 */
ok_hashes AS (
    SELECT DISTINCT
           "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "status" = 1
      AND ("call_type" IS NULL OR "call_type" = 'call')
      AND "block_timestamp" < 1630454400000000          -- 2021-09-01 in µs
),

/* 2.  Successful value-carrying transactions that match the hashes above
       (value may be zero – still pays gas)                       */
tx AS (
    SELECT *
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  "receipt_status" = 1
      AND  "block_timestamp" < 1630454400000000
      AND  "hash" IN (SELECT "transaction_hash" FROM ok_hashes)
),

/* 3.  Outgoing sums (value + gas) per sender */
outgoing AS (
    SELECT
        "from_address"                                     AS addr,
        SUM("value" + "receipt_gas_used" * "gas_price")    AS out_wei
    FROM   tx
    GROUP BY "from_address"
),

/* 4.  Incoming sums (value) per recipient */
incoming AS (
    SELECT
        "to_address"                                       AS addr,
        SUM("value")                                       AS in_wei
    FROM   tx
    GROUP BY "to_address"
)

/* 5.  Combine in / out and compute net balance,
       then return the 10 largest net holders            */
SELECT
    COALESCE(i.addr, o.addr)                                    AS address,
    (COALESCE(i.in_wei , 0) - COALESCE(o.out_wei, 0))           AS net_balance_wei
FROM   incoming i
FULL OUTER JOIN outgoing o
          ON i.addr = o.addr
ORDER BY net_balance_wei DESC NULLS LAST
LIMIT 10;