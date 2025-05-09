/*  Maximum & minimum final balances per Bitcoin-Cash address type
    for transactions that occurred between
    2014-03-01 00:00 UTC  ≤  block_timestamp  <  2014-04-01 00:00 UTC     */

WITH period AS (
    SELECT
        1393632000000000::NUMBER AS ts_start,   -- 2014-03-01 in µs
        1396310400000000::NUMBER AS ts_end      -- 2014-04-01 in µs
),

/*-------------------------------------------------------*
 | 1)  Credits = OUTPUT values (positive for receiver)   |
 *-------------------------------------------------------*/
credits AS (
    SELECT
        a.value::STRING                 AS "address",
        o."type",
        SUM(o."value"::FLOAT)           AS "credit"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o,
          LATERAL FLATTEN(input => o."addresses") a,
          period p
    WHERE o."block_timestamp" >= p.ts_start
      AND o."block_timestamp" <  p.ts_end
    GROUP BY a.value::STRING, o."type"
),

/*-------------------------------------------------------*
 | 2)  Debits = INPUT values (negative for sender)       |
 *-------------------------------------------------------*/
debits AS (
    SELECT
        a.value::STRING                 AS "address",
        i."type",
        SUM(i."value"::FLOAT)           AS "debit"
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   i,
          LATERAL FLATTEN(input => i."addresses") a,
          period p
    WHERE i."block_timestamp" >= p.ts_start
      AND i."block_timestamp" <  p.ts_end
    GROUP BY a.value::STRING, i."type"
),

/*----------------------------------------------*
 | 3)  Net balance per address (credits-debits) |
 *----------------------------------------------*/
balances AS (
    SELECT
        COALESCE(c."address", d."address")                AS "address",
        COALESCE(c."type"   , d."type")                   AS "type",
        COALESCE(c."credit", 0) - COALESCE(d."debit", 0)  AS "net_balance"
    FROM   credits  c
    FULL JOIN debits   d
           ON c."address" = d."address"
)

/*------------------------------------------------------*
 | 4)  Final result: max & min balance per address type |
 *------------------------------------------------------*/
SELECT
    "type",
    MAX("net_balance") AS "max_final_balance",
    MIN("net_balance") AS "min_final_balance"
FROM   balances
GROUP  BY "type";