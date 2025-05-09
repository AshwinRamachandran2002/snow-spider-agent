WITH "bad_tx" AS (   -- transactions that include traces with disallowed call‑types
    SELECT DISTINCT "transaction_hash"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "call_type" IS NOT NULL
      AND  LOWER("call_type") <> 'call'
), 

"valid_tx" AS (      -- successful transactions prior to 2021‑09‑01 with allowed call‑types
    SELECT *
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    WHERE  t."receipt_status" = 1
      AND  t."block_timestamp" < 1630454400000000        -- 2021‑09‑01 00:00:00 UTC (micro‑seconds)
      AND  t."hash" NOT IN (SELECT "transaction_hash" FROM "bad_tx")
), 

"deltas" AS (        -- balance changes (value transfers + fees)
    ------------------------------------------------------------------
    -- Sender  : pays value  +  pays fee  (negative delta)
    ------------------------------------------------------------------
    SELECT  t."from_address"                                              AS addr,
            - ( CAST(t."value" AS NUMBER(38,0))                           -- value sent
               + CAST(t."receipt_gas_used"                                 
                      * COALESCE(t."receipt_effective_gas_price",
                                 t."gas_price") AS NUMBER(38,0))          -- fee paid
              )                                                           AS delta
    FROM    "valid_tx" t

    UNION ALL
    ------------------------------------------------------------------
    -- Recipient : receives value (positive delta)
    ------------------------------------------------------------------
    SELECT  t."to_address"                                                AS addr,
            CAST(t."value" AS NUMBER(38,0))                               AS delta
    FROM    "valid_tx" t
    WHERE   t."to_address" IS NOT NULL

    UNION ALL
    ------------------------------------------------------------------
    -- Miner : receives fee (positive delta)
    ------------------------------------------------------------------
    SELECT  b."miner"                                                     AS addr,
            CAST(t."receipt_gas_used"
                 * COALESCE(t."receipt_effective_gas_price",
                            t."gas_price") AS NUMBER(38,0))               AS delta
    FROM    "valid_tx" t
    JOIN    CRYPTO.CRYPTO_ETHEREUM.BLOCKS b
              ON b."number" = t."block_number"
)

SELECT   addr           AS "address",
         SUM(delta)     AS "balance_wei"
FROM     "deltas"
WHERE    addr IS NOT NULL
GROUP BY addr
ORDER BY "balance_wei" DESC NULLS LAST
LIMIT    10;