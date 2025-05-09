WITH
/* ----------------------------------------------------------------------
   Positive leg : transaction outputs (credits)
---------------------------------------------------------------------- */
out_credits AS (
    SELECT
        o."type"                                                       AS "addr_type",
        f.value::STRING                                                AS "address",
        o."value"::NUMBER(38,9)                                        AS "amount"      -- credit  (+)
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
          LATERAL FLATTEN (INPUT => o."addresses") f
    WHERE o."block_timestamp" >= 1393632000000000      -- 2014-03-01 00:00:00 UTC
      AND o."block_timestamp" <  1396310400000000      -- 2014-04-01 00:00:00 UTC
),

/* ----------------------------------------------------------------------
   Negative leg : transaction inputs (debits)
---------------------------------------------------------------------- */
in_debits AS (
    SELECT
        i."type"                                                       AS "addr_type",
        f.value::STRING                                                AS "address",
        -1 * i."value"::NUMBER(38,9)                                   AS "amount"      -- debit (-)
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS" i,
          LATERAL FLATTEN (INPUT => i."addresses") f
    WHERE i."block_timestamp" >= 1393632000000000      -- 2014-03-01 00:00:00 UTC
      AND i."block_timestamp" <  1396310400000000      -- 2014-04-01 00:00:00 UTC
),

/* ----------------------------------------------------------------------
   Double-entry book – net balance per address
---------------------------------------------------------------------- */
addr_balances AS (
    SELECT
        "addr_type",
        "address",
        SUM("amount") AS "balance"
    FROM (
        SELECT * FROM out_credits
        UNION ALL
        SELECT * FROM in_debits
    )
    GROUP BY "addr_type", "address"
)

/* ----------------------------------------------------------------------
   Result : max / min final balances by address type
---------------------------------------------------------------------- */
SELECT
    "addr_type",
    MAX("balance") AS "max_final_balance",
    MIN("balance") AS "min_final_balance"
FROM   addr_balances
GROUP  BY "addr_type"
ORDER  BY "addr_type";