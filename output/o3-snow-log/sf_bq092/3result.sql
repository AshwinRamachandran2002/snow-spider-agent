-- highest and lowest DASH balances for April-2023
WITH april_blocks AS (          -- blocks that belong to April-2023
    SELECT "number"
    FROM   CRYPTO.CRYPTO_DASH.BLOCKS
    WHERE  "timestamp_month" = '2023-04-01'
),
entries AS (                    -- double-entry rows (outputs = +, inputs = –)
    ------------------------------------------------------------------ outputs
    SELECT
        ARRAY_TO_STRING(PARSE_JSON(o."addresses"), ',')          AS "address",
        o."type"                                                 AS "type",
        CAST(o."value" AS DECIMAL(38,9))                         AS "amount"
    FROM   CRYPTO.CRYPTO_DASH.OUTPUTS o
    JOIN   april_blocks        b  ON o."block_number" = b."number"
    
    UNION ALL
    ------------------------------------------------------------------ inputs
    SELECT
        ARRAY_TO_STRING(PARSE_JSON(i."addresses"), ',')          AS "address",
        i."type"                                                 AS "type",
        -CAST(i."value" AS DECIMAL(38,9))                        AS "amount"
    FROM   CRYPTO.CRYPTO_DASH.INPUTS  i
    JOIN   april_blocks        b  ON i."block_number" = b."number"
),
balances AS (                  -- net balance per address & type
    SELECT
        "address",
        "type",
        SUM("amount") AS "balance"
    FROM   entries
    GROUP  BY "address", "type"
),
ranked AS (                     -- rank to find highest & lowest
    SELECT
        "address",
        "type",
        "balance",
        ROW_NUMBER() OVER (ORDER BY "balance" DESC) AS r_high,
        ROW_NUMBER() OVER (ORDER BY "balance" ASC)  AS r_low
    FROM   balances
)
SELECT
    CASE WHEN r_high = 1 THEN 'HIGHEST' ELSE 'LOWEST' END AS "balance_rank",
    "address",
    "type",
    "balance"
FROM   ranked
WHERE  r_high = 1 OR r_low = 1;