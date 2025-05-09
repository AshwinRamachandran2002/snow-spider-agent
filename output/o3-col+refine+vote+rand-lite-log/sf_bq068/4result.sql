WITH tx_side_entries AS (

    /* +++++++++  CREDITS  (outputs)  +++++++++ */
    SELECT  
        f.value::STRING                      AS "address",
        o."type"                             AS "address_type",
        TO_NUMBER(o."value")                 AS amount          -- positive (credit)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS" o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp" BETWEEN 1393632000000000  -- 2014-03-01 00:00:00 UTC
                                 AND     1396310400000000  -- 2014-04-01 00:00:00 UTC

    UNION ALL

    /* +++++++++  DEBITS  (inputs)  +++++++++ */
    SELECT  
        f.value::STRING                      AS "address",
        i."type"                             AS "address_type",
        - TO_NUMBER(i."value")               AS amount          -- negative (debit)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"  i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp" BETWEEN 1393632000000000
                                 AND     1396310400000000
),

/* ---------  compute final balance per address  --------- */
address_balances AS (
    SELECT
        "address",
        "address_type",
        SUM(amount)  AS final_balance
    FROM tx_side_entries
    GROUP BY "address", "address_type"
)

/* ---------  min / max balance by script (address) type  --------- */
SELECT
    "address_type"             AS "type",
    MIN(final_balance)         AS min_final_balance,
    MAX(final_balance)         AS max_final_balance
FROM address_balances
GROUP BY "address_type";