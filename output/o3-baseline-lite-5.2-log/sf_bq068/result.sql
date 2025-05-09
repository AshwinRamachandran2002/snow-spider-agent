WITH tx_values AS (

    /* + credits : transaction outputs */
    SELECT
        addr.value::STRING                   AS address ,
        o."type"                            AS address_type ,
        o."value"::FLOAT                    AS amount      -- credit
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"  o ,
         LATERAL FLATTEN( INPUT => o."addresses") addr
    WHERE  o."block_timestamp" >= DATE_PART(epoch_microseconds , TO_TIMESTAMP_NTZ('2014-03-01'))
      AND  o."block_timestamp" <  DATE_PART(epoch_microseconds , TO_TIMESTAMP_NTZ('2014-04-01'))

    UNION ALL

    /* – debits : transaction inputs */
    SELECT
        addr.value::STRING                   AS address ,
        i."type"                            AS address_type ,
       -i."value"::FLOAT                    AS amount       -- debit (negative)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"   i ,
         LATERAL FLATTEN( INPUT => i."addresses") addr
    WHERE  i."block_timestamp" >= DATE_PART(epoch_microseconds , TO_TIMESTAMP_NTZ('2014-03-01'))
      AND  i."block_timestamp" <  DATE_PART(epoch_microseconds , TO_TIMESTAMP_NTZ('2014-04-01'))

),

/* balance per (address , address_type) */
balances AS (
    SELECT
        address_type ,
        address ,
        SUM(amount)  AS final_balance
    FROM tx_values
    GROUP BY address_type , address
)

/* max / min final balances inside each address type */
SELECT
    address_type                                       ,
    MAX(final_balance) AS max_final_balance            ,
    MIN(final_balance) AS min_final_balance
FROM balances
GROUP BY address_type
ORDER BY address_type;