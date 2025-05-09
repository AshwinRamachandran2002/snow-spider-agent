WITH filtered_transfers AS (
    SELECT
        TO_NUMBER("value")                                   AS value_num,
        FLOOR("block_timestamp" / 3600000000)                AS hour_bucket,   -- µs ⇒ hours
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)        AS ts              -- µs ⇒ timestamp
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN 1546300800000000          -- 2019‑01‑01 00:00:00 UTC
                                AND 1609459199000000          -- 2020‑12‑31 23:59:59 UTC
), hourly_avg AS (
    /* average value of transfers inside each hour bucket */
    SELECT
        hour_bucket,
        YEAR(ts)                    AS yr,
        AVG(value_num)              AS avg_value_per_hour
    FROM filtered_transfers
    GROUP BY hour_bucket, yr
), yearly_hourly_avg AS (
    /* overall average of those hourly averages for each year */
    SELECT
        yr,
        AVG(avg_value_per_hour)     AS avg_hourly_value
    FROM hourly_avg
    GROUP BY yr
)
SELECT
    MAX(CASE WHEN yr = 2019 THEN avg_hourly_value END) AS avg_hourly_value_2019,
    MAX(CASE WHEN yr = 2020 THEN avg_hourly_value END) AS avg_hourly_value_2020,
    MAX(CASE WHEN yr = 2020 THEN avg_hourly_value END)
  - MAX(CASE WHEN yr = 2019 THEN avg_hourly_value END) AS difference_2020_minus_2019
FROM yearly_hourly_avg;