WITH hourly AS (
    SELECT
        CASE
            WHEN "block_timestamp" < 1577836800000000 THEN 2019
            ELSE 2020
        END                                                AS "yr",
        FLOOR("block_timestamp"/3600000000) * 3600000000   AS "hour_ts",
        SUM("value"::NUMBER)                               AS "hour_value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
      AND "block_timestamp" BETWEEN 1546300800000000  /* 2019-01-01 */
                               AND 1609372799000000  /* 2020-12-31 */
    GROUP BY 1,2
),
deltas AS (
    SELECT
        "yr",
        ABS("hour_value" - LAG("hour_value") OVER (PARTITION BY "yr" ORDER BY "hour_ts")) AS "delta"
    FROM hourly
),
avg_changes AS (
    SELECT
        "yr",
        AVG("delta") AS "avg_hourly_change"
    FROM deltas
    WHERE "delta" IS NOT NULL
    GROUP BY "yr"
)
SELECT
    MAX(CASE WHEN "yr" = 2020 THEN "avg_hourly_change" END) -
    MAX(CASE WHEN "yr" = 2019 THEN "avg_hourly_change" END) AS "difference_2020_minus_2019"
FROM avg_changes;