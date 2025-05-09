WITH output_balances AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')                       AS "address",
        "type",
        SUM(CAST("value" AS DECIMAL(38,9)))                     AS "balance_part"
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS o
    JOIN CRYPTO.CRYPTO_DASH.BLOCKS  b
          ON o."block_number" = b."number"
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY ARRAY_TO_STRING("addresses", ','), "type"
),
input_balances AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')                       AS "address",
        "type",
        -SUM(CAST("value" AS DECIMAL(38,9)))                    AS "balance_part"
    FROM CRYPTO.CRYPTO_DASH.INPUTS i
    JOIN CRYPTO.CRYPTO_DASH.BLOCKS  b
          ON i."block_number" = b."number"
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY ARRAY_TO_STRING("addresses", ','), "type"
),
combined AS (
    SELECT * FROM output_balances
    UNION ALL
    SELECT * FROM input_balances
),
balances AS (
    SELECT
        "address",
        "type",
        SUM("balance_part")                                     AS "balance"
    FROM combined
    GROUP BY "address", "type"
),
ranked AS (
    SELECT
        "address",
        "type",
        "balance",
        RANK() OVER (ORDER BY "balance" DESC)                   AS r_high,
        RANK() OVER (ORDER BY "balance" ASC)                    AS r_low
    FROM balances
)
SELECT
    "address",
    "type",
    "balance"
FROM ranked
WHERE r_high = 1
   OR r_low  = 1
ORDER BY "balance" DESC NULLS LAST;