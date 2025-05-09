WITH cutoff AS (                                   -- 2021‑09‑01 00:00:00 UTC
    SELECT 1630454400000000::NUMBER AS ts
),

/* -----------------------------------------------------------------
   1. Address that initiated the most successful calls (status = 1)
      before the cut‑off, excluding delegatecall / callcode / staticcall
   ----------------------------------------------------------------- */
top_address AS (
    SELECT "from_address" AS address
    FROM   "CRYPTO"."CRYPTO_ETHEREUM"."TRACES" tr
           JOIN cutoff c ON tr."block_timestamp" < c.ts
    WHERE  tr."status" = 1
      AND ( tr."call_type" IS NULL
            OR tr."call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') )
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

/* -----------------------------------------------------------------
   2. Net Wei transferred to / from that address in ALL successful
      traces (incl. internal, reward, create, suicide, etc.) that
      satisfy the same call‑type filter and date filter
   ----------------------------------------------------------------- */
transfer_net AS (
    SELECT
          SUM(CASE WHEN tr."to_address"   = ta.address THEN tr."value" ELSE 0 END)
        - SUM(CASE WHEN tr."from_address" = ta.address THEN tr."value" ELSE 0 END)
        AS net_transfer_wei
    FROM   "CRYPTO"."CRYPTO_ETHEREUM"."TRACES" tr
           JOIN cutoff      c  ON tr."block_timestamp" < c.ts
           JOIN top_address ta ON tr."to_address" = ta.address
                               OR tr."from_address" = ta.address
    WHERE  tr."status" = 1
      AND ( tr."call_type" IS NULL
            OR tr."call_type" NOT IN ('delegatecall', 'callcode', 'staticcall') )
),

/* -----------------------------------------------------------------
   3. Gas fees (Wei) paid by that address in successful top‑level
      transactions before the cut‑off
   ----------------------------------------------------------------- */
gas_fee AS (
    SELECT SUM( trx."receipt_gas_used"
                * COALESCE(trx."receipt_effective_gas_price", trx."gas_price") )
           AS gas_fee_wei
    FROM   "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS" trx
           JOIN cutoff      c  ON trx."block_timestamp" < c.ts
           JOIN top_address ta ON trx."from_address" = ta.address
    WHERE  trx."receipt_status" = 1
),

/* -----------------------------------------------------------------
   4. Final balance in Ether (rounded to 4 decimals as requested)
   ----------------------------------------------------------------- */
final_balance AS (
    SELECT
        ta.address                                            AS address,
        ROUND( ( tn.net_transfer_wei
                - COALESCE(gf.gas_fee_wei, 0) ) / 1e18 , 4 )  AS final_balance_ether
    FROM top_address  ta
    CROSS JOIN transfer_net tn
    CROSS JOIN gas_fee     gf
)

SELECT address, final_balance_ether
FROM   final_balance;