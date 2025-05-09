WITH
/*-----------------------------------------------------------
1) Credits – every output gives a positive amount
-----------------------------------------------------------*/
OUTPUT_CREDITS AS (
    SELECT
        addr.value::STRING         AS ADDRESS ,
        o."type"                   AS ADDRESS_TYPE ,
        o."value"::NUMBER(38,8)    AS AMOUNT                 -- credit (+)
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o
         ,LATERAL FLATTEN( INPUT => PARSE_JSON(o."addresses") ) addr
    WHERE o."block_timestamp" >= 1393632000000000   -- 2014-03-01
      AND o."block_timestamp" <  1396310400000000   -- 2014-04-01
),
/*-----------------------------------------------------------
2) Debits – every input spends coins (negative amount)
-----------------------------------------------------------*/
INPUT_DEBITS AS (
    SELECT
        addr.value::STRING         AS ADDRESS ,
        i."type"                   AS ADDRESS_TYPE ,
       -i."value"::NUMBER(38,8)    AS AMOUNT                 -- debit (−)
    FROM  CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   i
         ,LATERAL FLATTEN( INPUT => PARSE_JSON(i."addresses") ) addr
    WHERE i."block_timestamp" >= 1393632000000000
      AND i."block_timestamp" <  1396310400000000
),
/*-----------------------------------------------------------
3) Net balance per address (credits + debits)
-----------------------------------------------------------*/
ADDRESS_BALANCES AS (
    SELECT
        ADDRESS ,
        ADDRESS_TYPE ,
        SUM(AMOUNT) AS FINAL_BALANCE
    FROM (
        SELECT * FROM OUTPUT_CREDITS
        UNION ALL
        SELECT * FROM INPUT_DEBITS
    )
    GROUP BY ADDRESS , ADDRESS_TYPE
)
/*-----------------------------------------------------------
4) Max & Min final balances per address-type
-----------------------------------------------------------*/
SELECT
    ADDRESS_TYPE ,
    MAX(FINAL_BALANCE) AS MAX_FINAL_BALANCE ,
    MIN(FINAL_BALANCE) AS MIN_FINAL_BALANCE
FROM ADDRESS_BALANCES
GROUP BY ADDRESS_TYPE
ORDER BY ADDRESS_TYPE;