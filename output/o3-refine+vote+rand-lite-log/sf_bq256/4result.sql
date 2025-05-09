WITH

-- 1. Address that sent the most successful transactions before 1‑Sep‑2021
addr AS (
    SELECT  "from_address"  AS addr
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE   "block_timestamp" < 1630454400000000      -- 2021‑09‑01 00:00:00 UTC
      AND   "receipt_status" = 1                      -- successful
    GROUP BY "from_address"
    QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "from_address") = 1
),

/* ---------- 2. Monetary flows (all amounts kept in WEI) ---------- */

-- outgoing user‑level transactions  (value  +  gas fee)
tx_out AS (
    SELECT
        -( COALESCE(TO_NUMBER("value"),0)
         + COALESCE(TO_NUMBER("receipt_effective_gas_price"),TO_NUMBER("gas_price"),0)
           * COALESCE(TO_NUMBER("receipt_gas_used"),0) )                          AS amt_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN addr a  ON t."from_address" = a.addr
    WHERE t."block_timestamp" < 1630454400000000
      AND t."receipt_status" = 1
),

-- incoming user‑level transactions (value only)
tx_in AS (
    SELECT  TO_NUMBER("value") AS amt_wei
    FROM    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN    addr a  ON t."to_address" = a.addr
    WHERE   t."block_timestamp" < 1630454400000000
      AND   t."receipt_status"  = 1
),

-- relevant traces (exclude delegatecall / callcode / staticcall)
flt_traces AS (
    SELECT *
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES  tr
    WHERE  tr."block_timestamp" < 1630454400000000
      AND (
              (tr."trace_type" = 'call' AND COALESCE(tr."call_type",'') NOT IN
                   ('delegatecall','callcode','staticcall'))
           OR tr."trace_type" IN ('create','reward','suicide','selfdestruct')
          )
),

-- outgoing internal value transfers
tr_out AS (
    SELECT  -TO_NUMBER("value") AS amt_wei
    FROM    flt_traces  tr
    JOIN    addr a  ON tr."from_address" = a.addr
),

-- incoming internal value transfers  (includes miner rewards)
tr_in  AS (
    SELECT  TO_NUMBER("value") AS amt_wei
    FROM    flt_traces  tr
    JOIN    addr a  ON tr."to_address" = a.addr
)

/* ---------- 3. Final balance in Ether ---------- */
SELECT
       a.addr                                  AS "ADDRESS",
       (SUM(amt_wei) / 1e18)                   AS "FINAL_ETHER_BALANCE"
FROM   (
          SELECT * FROM tx_out
          UNION ALL
          SELECT * FROM tx_in
          UNION ALL
          SELECT * FROM tr_out
          UNION ALL
          SELECT * FROM tr_in
       ) flows
JOIN   addr a  ON 1=1
GROUP  BY a.addr;