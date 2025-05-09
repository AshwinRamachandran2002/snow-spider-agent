WITH
/* ---------------------------------------------------------
1.  Address that initiated the most successful transactions
    before 2021‑09‑01 (UTC) whose top‑level trace is NOT
    delegatecall, callcode or staticcall
---------------------------------------------------------- */
top_sender AS (
    SELECT
        t."from_address"  AS address,
        COUNT(DISTINCT t."hash") AS tx_cnt
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS  t
    JOIN CRYPTO.CRYPTO_ETHEREUM.TRACES        tr
          ON tr."transaction_hash" = t."hash"
    WHERE t."block_timestamp" < 1630454400000000          -- 2021‑09‑01 UTC
      AND t."receipt_status" = 1                          -- successful tx
      AND tr."trace_address" = '0'                        -- top‑level call
      AND (tr."call_type" IS NULL
           OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
    GROUP BY t."from_address"
    QUALIFY ROW_NUMBER() OVER (ORDER BY tx_cnt DESC, t."from_address") = 1
),

/* ---------------------------------------------------------
2.  Out‑going Wei  =  explicit value  +  gas fee
---------------------------------------------------------- */
outgoing AS (
    SELECT
        SUM( TO_DECIMAL(COALESCE(t."value",0)) +
             TO_DECIMAL(COALESCE(t."receipt_gas_used",0)) *
             TO_DECIMAL(COALESCE(t."gas_price",0)) )      AS out_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender s
      ON LOWER(t."from_address") = LOWER(s.address)
    WHERE t."block_timestamp" < 1630454400000000
      AND t."receipt_status" = 1
),

/* ---------------------------------------------------------
3.  Direct in‑coming Wei (explicit receiver)
---------------------------------------------------------- */
incoming AS (
    SELECT
        SUM( TO_DECIMAL(COALESCE(t."value",0)) )          AS in_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    JOIN top_sender s
      ON LOWER(t."to_address") = LOWER(s.address)
    WHERE t."block_timestamp" < 1630454400000000
      AND t."receipt_status" = 1
),

/* ---------------------------------------------------------
4.  Internal transfers captured in TRACES (call only)
---------------------------------------------------------- */
internal_flow AS (
    SELECT
        SUM(
            CASE WHEN LOWER(tr."to_address") = LOWER(s.address)
                 THEN TO_DECIMAL(COALESCE(tr."value",0)) ELSE 0 END
        ) AS internal_in,
        SUM(
            CASE WHEN LOWER(tr."from_address") = LOWER(s.address)
                 THEN TO_DECIMAL(COALESCE(tr."value",0)) ELSE 0 END
        ) AS internal_out
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
          ON t."hash" = tr."transaction_hash"
    CROSS JOIN top_sender s
    WHERE t."block_timestamp" < 1630454400000000
      AND t."receipt_status" = 1
      AND tr."trace_type" = 'call'
      AND (tr."call_type" IS NULL
           OR tr."call_type" NOT IN ('delegatecall','callcode','staticcall'))
),

/* ---------------------------------------------------------
5.  Miner rewards (block / uncle) paid to the address
---------------------------------------------------------- */
rewards AS (
    SELECT
        SUM( TO_DECIMAL(COALESCE(tr."value",0)) )         AS reward_wei
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    JOIN top_sender s
      ON LOWER(tr."to_address") = LOWER(s.address)
    WHERE tr."block_timestamp" < 1630454400000000
      AND tr."reward_type" IN ('block','uncle')
)

/* ---------------------------------------------------------
6.  Final balance in Ether (4 decimal places)
---------------------------------------------------------- */
SELECT
    s.address                                            AS address,
    ROUND(
          ( COALESCE(i.in_wei ,0)
          + COALESCE(f.internal_in ,0)
          + COALESCE(r.reward_wei ,0)
          - COALESCE(o.out_wei ,0)
          - COALESCE(f.internal_out,0)
          ) / 1e18
        , 4)                                             AS final_balance_ether
FROM top_sender   s
LEFT JOIN outgoing      o ON TRUE
LEFT JOIN incoming      i ON TRUE
LEFT JOIN internal_flow f ON TRUE
LEFT JOIN rewards       r ON TRUE;