/*--------------------------------------------------------------------
  Double-entry bookkeeping on Bitcoin Cash transactions
  Period          : 2014-03-01 00:00 UTC  →  2014-04-01 00:00 UTC
  Debit (Inputs)  : negative amount
  Credit (Outputs): positive amount
  Goal            : per script / address type
                    – compute each address’ final balance
                    – return the maximum and minimum balance per type
--------------------------------------------------------------------*/
WITH date_limits AS (      -- micro-second timestamps
  SELECT
      1393632000000000::NUMBER AS start_ts ,   -- 2014-03-01
      1396310400000000::NUMBER AS end_ts       -- 2014-04-01
),

/* credits ----------------------------------------------------------*/
output_moves AS (
  SELECT
      f.value::STRING         AS address ,
      o."type"                AS address_type ,
      o."value"               AS amount            -- positive
  FROM  CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o
        ,date_limits d
        ,LATERAL FLATTEN( INPUT => o."addresses") f
  WHERE o."block_timestamp" >= d.start_ts
    AND o."block_timestamp" <  d.end_ts
),

/* debits -----------------------------------------------------------*/
input_moves AS (
  SELECT
      f.value::STRING         AS address ,
      i."type"                AS address_type ,
     -i."value"               AS amount            -- negative
  FROM  CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i
        ,date_limits d
        ,LATERAL FLATTEN( INPUT => i."addresses") f
  WHERE i."block_timestamp" >= d.start_ts
    AND i."block_timestamp" <  d.end_ts
),

/* unified ledger ---------------------------------------------------*/
ledger AS (
  SELECT * FROM output_moves
  UNION ALL
  SELECT * FROM input_moves
),

/* balance per individual address ----------------------------------*/
balances AS (
  SELECT
      address_type ,
      address ,
      SUM(amount)  AS balance
  FROM ledger
  GROUP BY address_type , address
)

/* final max / min per script-type ---------------------------------*/
SELECT
    address_type ,
    MAX(balance) AS max_balance ,
    MIN(balance) AS min_balance
FROM balances
GROUP BY address_type
ORDER BY address_type;