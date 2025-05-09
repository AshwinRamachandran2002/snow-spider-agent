WITH
-- 1. all successful user-transactions before 1 Sep 2021 (UTC) whose root-call is NOT delegatecall/callcode/staticcall
tx_success AS (
    SELECT
        "hash",
        "from_address"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE  "receipt_status" = 1
      AND  "block_timestamp" < 1630454400000000          -- 2021-09-01 00:00:00 UTC in µs
      AND NOT EXISTS (                                   -- discard transactions whose root call is delegate/callcode/staticcall
              SELECT 1
              FROM CRYPTO.CRYPTO_ETHEREUM.TRACES r
              WHERE r."transaction_hash" = t."hash"
                AND r."trace_address" = ''
                AND r."call_type" IN ('delegatecall','callcode','staticcall')
          )
),
-- 2. the address that sent the most such transactions
top_sender AS (
    SELECT "from_address"        AS addr
    FROM   tx_success
    GROUP  BY "from_address"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),

/* -----------------------------------------------------------------------
   BALANCE CALCULATION FOR THAT ADDRESS:
   incoming  = external txs to the address  +   trace CALL value transfers to it
             + miner / ommer rewards to it  (trace_type = 'reward')
   outgoing  = external txs from the address + trace CALL value transfers from it
   gas fees  = Σ(receipt_gas_used * effective_gas_price) for all txs sent by it
-------------------------------------------------------------------------*/
-- 3a. external transactions (value field is already in Wei)
tx_flows AS (
    SELECT
        CASE WHEN t."to_address" = s.addr THEN 'in' ELSE 'out' END       AS dir,
        t."value"                                                      AS val,
        CASE WHEN t."from_address" = s.addr
             THEN t."receipt_gas_used" * COALESCE(t."receipt_effective_gas_price",t."gas_price")
             ELSE 0 END                                                AS gas_fee
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender             s ON t."from_address" = s.addr OR t."to_address" = s.addr
),

-- 3b. internal value transfers coming from regular CALL-type traces
trace_calls AS (
    SELECT
        CASE WHEN tr."to_address" = s.addr THEN 'in' ELSE 'out' END     AS dir,
        tr."value"                                                      AS val
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN top_sender               s ON tr."from_address" = s.addr OR tr."to_address" = s.addr
    WHERE tr."trace_type" = 'call'
      AND COALESCE(tr."call_type",'') NOT IN ('delegatecall','callcode','staticcall')
),

-- 3c. miner / ommer rewards that paid the address
trace_rewards AS (
    SELECT 'in'               AS dir,
           tr."value"         AS val
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN top_sender           s ON tr."to_address" = s.addr
    WHERE tr."trace_type" = 'reward'
),

-- 4. union every monetary movement
all_movements AS (
      SELECT dir, val, gas_fee FROM tx_flows
 UNION ALL
      SELECT dir, val, 0       FROM trace_calls
 UNION ALL
      SELECT dir, val, 0       FROM trace_rewards
),

-- 5. aggregate to obtain final Wei balance
aggregate AS (
    SELECT
        SUM(CASE WHEN dir='in'  THEN val ELSE 0 END)                    AS wei_in,
        SUM(CASE WHEN dir='out' THEN val ELSE 0 END)                    AS wei_out,
        SUM(gas_fee)                                                    AS wei_gas
    FROM all_movements
)

-- 6. present result in Ether
SELECT
    s.addr                                                 AS "address",
    (wei_in - wei_out - wei_gas) / 1e18                    AS "final_balance_eth"
FROM aggregate, top_sender s;