WITH transfers_filtered AS (
    SELECT 
        "block_timestamp",
        TO_TIMESTAMP_NTZ("block_timestamp"/1e6)                  AS ts,
        CAST("value" AS NUMBER(38,0))                            AS val
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR LOWER("to_address") = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      AND  TO_TIMESTAMP_NTZ("block_timestamp"/1e6) >= '2019-01-01'
      AND  TO_TIMESTAMP_NTZ("block_timestamp"/1e6) <  '2021-01-01'
), hourly AS (
    SELECT 
        DATE_TRUNC('hour', ts)          AS hour_bucket,
        SUM(val)                        AS hourly_value
    FROM transfers_filtered
    GROUP BY hour_bucket
), yearly_avg AS (
    SELECT 
        YEAR(hour_bucket)               AS yr,
        AVG(hourly_value)               AS avg_hour_value
    FROM hourly
    GROUP BY yr
), pivoted AS (
    SELECT 
        MAX(CASE WHEN yr = 2020 THEN avg_hour_value END) AS avg_2020,
        MAX(CASE WHEN yr = 2019 THEN avg_hour_value END) AS avg_2019
    FROM yearly_avg
)
SELECT 
    avg_2020 - avg_2019 AS diff_avg_hourly_value
FROM pivoted;