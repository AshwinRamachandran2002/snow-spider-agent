WITH
filtered_transfers AS (
    SELECT
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)                    AS ts,
        CAST("value" AS NUMBER(38,0))                                     AS transfer_value
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
             LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
          OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
      AND TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) >= '2019-01-01' 
      AND TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) <  '2021-01-01'
),
hourly_totals AS (
    SELECT
        DATE_TRUNC('hour', ts)                       AS hour_bucket,
        SUM(transfer_value)                          AS hour_sum
    FROM filtered_transfers
    GROUP BY hour_bucket
),
hourly_changes AS (
    SELECT
        hour_bucket,
        hour_sum
      , hour_sum - LAG(hour_sum) OVER (ORDER BY hour_bucket) AS hour_change
    FROM hourly_totals
),
yearly_avg_change AS (
    SELECT
        EXTRACT(year FROM hour_bucket) AS yr,
        AVG(hour_change)               AS avg_hourly_change
    FROM hourly_changes
    WHERE hour_change IS NOT NULL
    GROUP BY yr
)
SELECT
    y2020.avg_hourly_change - y2019.avg_hourly_change AS diff_avg_hourly_change
FROM (SELECT avg_hourly_change FROM yearly_avg_change WHERE yr = 2019) y2019,
     (SELECT avg_hourly_change FROM yearly_avg_change WHERE yr = 2020) y2020;