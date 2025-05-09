/*--------------------------------------------------------------------
  Highest and Lowest Dash address balances for April-2023
--------------------------------------------------------------------*/
WITH month_blocks AS (          -- all Dash blocks in April-2023
    SELECT  "hash" AS block_hash
    FROM    CRYPTO.CRYPTO_DASH."BLOCKS"
    WHERE   "timestamp_month" = '2023-04-01'
),

/* build double-entry ledger : OUTPUT = credit (+), INPUT = debit (-) */
ledger AS (

    /* credits ----------------------------------------------------- */
    SELECT
        f.value::STRING                    AS address,
        o."type"                           AS addr_type,
        o."value"::NUMBER                  AS amt      -- positive
    FROM   CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN   month_blocks  b  ON o."block_hash" = b.block_hash
    ,      LATERAL FLATTEN(input => o."addresses") f

    UNION ALL

    /* debits ------------------------------------------------------ */
    SELECT
        f.value::STRING                    AS address,
        i."type"                           AS addr_type,
       -i."value"::NUMBER                  AS amt      -- negative
    FROM   CRYPTO.CRYPTO_DASH."INPUTS"  i
    JOIN   month_blocks  b  ON i."block_hash" = b.block_hash
    ,      LATERAL FLATTEN(input => i."addresses") f
),

/* net balance per address & script-type ---------------------------*/
balances AS (
    SELECT  address,
            addr_type,
            SUM(amt)   AS net_balance
    FROM    ledger
    GROUP   BY address, addr_type
)

/* highest and lowest ---------------------------------------------*/
SELECT address,
       addr_type AS "type",
       net_balance,
       'HIGHEST'  AS balance_rank
FROM   balances
QUALIFY ROW_NUMBER() OVER (ORDER BY net_balance DESC NULLS LAST) = 1

UNION ALL

SELECT address,
       addr_type AS "type",
       net_balance,
       'LOWEST'   AS balance_rank
FROM   balances
QUALIFY ROW_NUMBER() OVER (ORDER BY net_balance ASC NULLS LAST) = 1
;