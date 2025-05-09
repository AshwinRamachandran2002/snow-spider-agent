WITH filtered AS (
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1e6))              AS hour_bucket ,
        TRY_TO_DECIMAL("value")                                                AS value_dec
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN 1546300800000000     -- 2019‑01‑01 00:00:00 UTC
                               AND 1609459199000000     -- 2020‑12‑31 23:59:59 UTC
), hourly AS (
    SELECT
        hour_bucket,
        SUM(value_dec)                          AS hour_total
    FROM filtered
    GROUP BY hour_bucket
), changes AS (
    SELECT
        hour_bucket,
        ABS(hour_total
            - LAG(hour_total) OVER (ORDER BY hour_bucket)) AS hour_change
    FROM hourly
), yearly_avg AS (
    SELECT
        YEAR(hour_bucket)                       AS yr,
        AVG(hour_change)                        AS avg_hourly_change
    FROM changes
    WHERE hour_change IS NOT NULL
    GROUP BY yr
    HAVING yr IN (2019, 2020)
)
SELECT
      (SELECT avg_hourly_change FROM yearly_avg WHERE yr = 2020)
    - (SELECT avg_hourly_change FROM yearly_avg WHERE yr = 2019)  AS difference_avg_hourly_change;