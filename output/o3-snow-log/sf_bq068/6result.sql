/* -----------------------------------------------------------
   Maximum and minimum “final” balances by Bitcoin-Cash address
   type between 2014-03-01 and 2014-04-01 (UTC)

   –  Inputs  = debit  (negative)
   –  Outputs = credit (positive)
   –  Final balance per address = Σ(credits + debits)
   –  Report max / min balance for every address “type”
------------------------------------------------------------*/
WITH
/* credits --------------------------------------------------*/
credits AS (
    SELECT
        "type"                          AS address_type ,
        f.value::STRING                 AS address      ,
        "value"                         AS amount
    FROM  "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS"  o ,
          LATERAL FLATTEN(INPUT => PARSE_JSON(o."addresses")) f
    WHERE  o."block_timestamp" >= 1393632000000000   -- 2014-03-01 00:00:00 UTC
       AND o."block_timestamp" <  1396310400000000   -- 2014-04-01 00:00:00 UTC
),

/* debits ---------------------------------------------------*/
debits AS (
    SELECT
        "type"                          AS address_type ,
        f.value::STRING                 AS address      ,
       - "value"                        AS amount        -- negative
    FROM  "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS"   i ,
          LATERAL FLATTEN(INPUT => PARSE_JSON(i."addresses")) f
    WHERE  i."block_timestamp" >= 1393632000000000
       AND i."block_timestamp" <  1396310400000000
),

/* merge debits & credits ----------------------------------*/
ledger AS (
    SELECT * FROM credits
    UNION ALL
    SELECT * FROM debits
),

/* aggregate to final balance per address ------------------*/
balances AS (
    SELECT
        address_type ,
        address      ,
        SUM(amount)  AS final_balance
    FROM   ledger
    GROUP  BY address_type , address
)

/* report max / min balance by address type ----------------*/
SELECT
    address_type                    ,
    MAX(final_balance) AS max_balance ,
    MIN(final_balance) AS min_balance
FROM   balances
GROUP  BY address_type
ORDER  BY address_type;