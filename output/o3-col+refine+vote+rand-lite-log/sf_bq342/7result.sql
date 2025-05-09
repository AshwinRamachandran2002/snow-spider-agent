WITH filtered AS (
    /*  Hourly aggregated transfer value for each year (2019 & 2020)  */
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1e6))                       AS "hour_bucket",
        YEAR(TO_TIMESTAMP("block_timestamp" / 1e6))                                     AS "yr",
        SUM("value"::NUMBER)                                                            AS "hour_value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6)) BETWEEN '2019-01-01' AND '2020-12-31'
    GROUP BY 1,2
),
deltas AS (
    /*  Hour-to-hour absolute changes within each year  */
    SELECT
        "yr",
        ABS("hour_value" - LAG("hour_value") OVER (PARTITION BY "yr" ORDER BY "hour_bucket")) AS "delta"
    FROM filtered
),
avg_deltas AS (
    /*  Average hourly change per year  */
    SELECT
        "yr",
        AVG("delta") AS "avg_delta"
    FROM deltas
    WHERE "delta" IS NOT NULL
    GROUP BY "yr"
)
SELECT
    MAX(CASE WHEN "yr" = 2020 THEN "avg_delta" END)
  - MAX(CASE WHEN "yr" = 2019 THEN "avg_delta" END)        AS "difference_2020_minus_2019"
FROM avg_deltas;