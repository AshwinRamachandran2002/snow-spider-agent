WITH filtered AS (
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1000000))                    AS hour_bucket ,
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000))                                   AS yr          ,
        TO_NUMBER("value")                                                                AS value_num
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "block_timestamp" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00 UTC
                              AND     1609459200000000  -- 2021-01-01 00:00:00 UTC (exclusive upper bound)
      AND LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
),
hourly AS (
    SELECT
        yr,
        hour_bucket,
        SUM(value_num) AS total_value_hour
    FROM filtered
    GROUP BY yr, hour_bucket
),
yearly AS (
    SELECT
        yr,
        AVG(total_value_hour) AS avg_hour_value
    FROM hourly
    GROUP BY yr
)
SELECT
        COALESCE(MAX(CASE WHEN yr = 2020 THEN avg_hour_value END), 0)
      - COALESCE(MAX(CASE WHEN yr = 2019 THEN avg_hour_value END), 0)
        AS diff_avg_hourly_value_2020_minus_2019
FROM yearly;