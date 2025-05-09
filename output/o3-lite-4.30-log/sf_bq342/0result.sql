WITH hourly AS (
    SELECT
        DATE_TRUNC('HOUR', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "hr",
        SUM(TRY_TO_DECIMAL("value"))                                   AS "sum_value"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
           "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
        OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
      AND TO_TIMESTAMP("block_timestamp" / 1000000)
            BETWEEN '2019-01-01 00:00:00' AND '2020-12-31 23:59:59'
    GROUP BY "hr"
),
changes AS (
    SELECT
        "hr",
        "sum_value" - LAG("sum_value") OVER (ORDER BY "hr") AS "value_change"
    FROM hourly
)
SELECT
    ROUND(
        AVG(CASE WHEN YEAR("hr") = 2020 THEN "value_change" END)
      - AVG(CASE WHEN YEAR("hr") = 2019 THEN "value_change" END)
    , 4) AS avg_hourly_change_difference
FROM changes
WHERE "value_change" IS NOT NULL;