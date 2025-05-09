WITH filtered AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000) AS ts,
        TO_DECIMAL("value")                      AS val
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) BETWEEN '2019-01-01' AND '2020-12-31'
),
hourly AS (
    SELECT
        DATE_TRUNC('HOUR', ts) AS hour_ts,
        SUM(val)              AS hourly_value
    FROM filtered
    GROUP BY hour_ts
),
avg_by_year AS (
    SELECT
        YEAR(hour_ts)                AS yr,
        AVG(hourly_value)            AS avg_hourly_value
    FROM hourly
    GROUP BY yr
)
SELECT
    (SELECT avg_hourly_value FROM avg_by_year WHERE yr = 2020) -
    (SELECT avg_hourly_value FROM avg_by_year WHERE yr = 2019) AS diff_avg_hourly_value_2020_minus_2019;