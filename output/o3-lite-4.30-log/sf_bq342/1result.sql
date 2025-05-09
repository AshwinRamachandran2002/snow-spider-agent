WITH filtered AS (
    SELECT
        FLOOR("block_timestamp" / 3600000000)                    AS hour_bucket      -- µs → hours
      , "value"::DECIMAL(38,0)                                   AS token_value
      , CASE WHEN "block_timestamp" < 1577836800000000           -- 2020‑01‑01 00:00:00 UTC
             THEN 2019 ELSE 2020 END                            AS yr
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND ( "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f' )
      AND "block_timestamp" BETWEEN 1546300800000000            -- 2019‑01‑01 00:00:00
                               AND     1609459199000000         -- 2020‑12‑31 23:59:59
),
hourly AS (                       -- average value within each hour
    SELECT hour_bucket,
           yr,
           AVG(token_value) AS avg_token_value
    FROM   filtered
    GROUP  BY hour_bucket, yr
),
yearly AS (                       -- average of hourly averages per year
    SELECT yr,
           AVG(avg_token_value) AS avg_hourly_value
    FROM   hourly
    GROUP  BY yr
)
SELECT
    ROUND(
        MAX(CASE WHEN yr = 2020 THEN avg_hourly_value END) -
        MAX(CASE WHEN yr = 2019 THEN avg_hourly_value END)
    , 4) AS "avg_hourly_change_difference"
FROM yearly;