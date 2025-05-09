WITH input_tx AS (   /* Dash inputs = debits (negative amounts) */
    SELECT
        IFF( IS_ARRAY("addresses"),
             ARRAY_TO_STRING("addresses", ','),      /* join array values */
             "addresses"::STRING )            AS "address",
        "type",
        - "value"                             AS "amount"  /* debit */
    FROM CRYPTO.CRYPTO_DASH.INPUTS
    WHERE DATE_TRUNC('month',
                     TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
          ) = '2023-04-01'        /* April-2023 filter */
), 
output_tx AS (       /* Dash outputs = credits (positive amounts) */
    SELECT
        IFF( IS_ARRAY("addresses"),
             ARRAY_TO_STRING("addresses", ','),
             "addresses"::STRING )            AS "address",
        "type",
        "value"                              AS "amount"  /* credit */
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS
    WHERE DATE_TRUNC('month',
                     TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
          ) = '2023-04-01'        /* April-2023 filter */
), 
balances AS (        /* net balance per address & type */
    SELECT
        "address",
        "type",
        SUM("amount") AS "balance"
    FROM (
        SELECT * FROM input_tx
        UNION ALL
        SELECT * FROM output_tx
    )
    GROUP BY "address", "type"
), 
ranked AS (          /* rank to find highest / lowest */
    SELECT
        "address",
        "type",
        "balance",
        ROW_NUMBER() OVER (ORDER BY "balance" DESC) AS rn_high,
        ROW_NUMBER() OVER (ORDER BY "balance" ASC)  AS rn_low
    FROM balances
)
SELECT
    CASE WHEN rn_high = 1 THEN 'HIGHEST' ELSE 'LOWEST' END AS "balance_category",
    "address",
    "type",
    "balance"
FROM ranked
WHERE rn_high = 1 OR rn_low = 1
ORDER BY "balance_category";