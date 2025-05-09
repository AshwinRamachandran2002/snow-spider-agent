WITH BALANCES AS
(
    /*  credits  : Dash outputs  ( + value )
        debits   : Dash inputs   ( - value ) */
    SELECT
        /* concatenate every element in the address array, or cast to string
           when the variant is a single value                                    */
        CASE
            WHEN IS_ARRAY("addresses")
                 THEN ARRAY_TO_STRING("addresses", ',')
            ELSE "addresses"::string
        END                                                AS "address",
        "type",
        SUM("signed_value")                                AS "balance"
    FROM
    (
        /*  OUTPUTS  ->  credit  */
        SELECT
            "addresses",
            "type",
            "value"                                        AS "signed_value",
            "block_timestamp"
        FROM  CRYPTO.CRYPTO_DASH."OUTPUTS"

        UNION ALL

        /*  INPUTS   ->  debit   */
        SELECT
            "addresses",
            "type",
            - "value"                                      AS "signed_value",
            "block_timestamp"
        FROM  CRYPTO.CRYPTO_DASH."INPUTS"
    )
    /* keep only April‑2023 records (timestamps stored in µ‑seconds) */
    WHERE DATE_TRUNC('MONTH', TO_TIMESTAMP("block_timestamp" / 1000000))
          = '2023-04-01'
    GROUP BY 1, 2
)

/* pick the highest and lowest balances */
SELECT *
FROM BALANCES
WHERE "balance" = (SELECT MAX("balance") FROM BALANCES)
   OR "balance" = (SELECT MIN("balance") FROM BALANCES);