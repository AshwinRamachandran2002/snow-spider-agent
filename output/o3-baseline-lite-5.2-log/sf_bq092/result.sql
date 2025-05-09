/* highest and lowest Dash address balances for April‑2023 (double‑entry) */
WITH io_rows AS (   /* flatten every address that appears in INPUTS/OUTPUTS   */
    /* credits  (outputs) */
    SELECT
        f.value::string                                                  AS "ADDRESS",
        o."type"                                                         AS "TYPE",
        o."value"                                                        AS "AMOUNT"          -- positive (credit)
    FROM  CRYPTO.CRYPTO_DASH."OUTPUTS"  o
          JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b
               ON b."number" = o."block_number"
          ,   LATERAL FLATTEN( INPUT => PARSE_JSON(o."addresses") )  f
    WHERE b."timestamp_month" = '2023-04-01'

    UNION ALL

    /* debits  (inputs – negate the value) */
    SELECT
        f.value::string                                                  AS "ADDRESS",
        i."type"                                                         AS "TYPE",
        (-1) * i."value"                                                 AS "AMOUNT"          -- negative (debit)
    FROM  CRYPTO.CRYPTO_DASH."INPUTS"  i
          JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b
               ON b."number" = i."block_number"
          ,   LATERAL FLATTEN( INPUT => PARSE_JSON(i."addresses") )  f
    WHERE b."timestamp_month" = '2023-04-01'
),

balances AS (       /* net balance per address + type */
    SELECT
        "ADDRESS",
        "TYPE",
        SUM("AMOUNT")                       AS "BALANCE"
    FROM io_rows
    GROUP BY "ADDRESS", "TYPE"
),

extremes AS (       /* highest & lowest balances */
    ( SELECT 'HIGHEST' AS "CATEGORY", *
      FROM balances
      ORDER BY "BALANCE" DESC NULLS LAST, "ADDRESS"
      LIMIT 1 )
    UNION ALL
    ( SELECT 'LOWEST'  AS "CATEGORY", *
      FROM balances
      ORDER BY "BALANCE" ASC NULLS LAST, "ADDRESS"
      LIMIT 1 )
)

SELECT *             -- final answer
FROM   extremes;