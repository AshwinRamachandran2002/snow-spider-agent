WITH filtered AS (   /* keep only token transfers that match token & addresses of interest */
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1e6)                AS ts,          -- micro‑seconds → TIMESTAMP
        CAST("value" AS NUMBER)                              AS tx_value
    FROM  CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address"  = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND TO_TIMESTAMP("block_timestamp" / 1e6)
          BETWEEN '2019-01-01 00:00:00' AND '2020-12-31 23:59:59'
), hourly AS (        /* total value moved each individual clock‑hour */
    SELECT
        DATE_TRUNC('hour', ts)          AS hour_bucket,
        YEAR(ts)                        AS yr,
        SUM(tx_value)                   AS hour_total_value
    FROM filtered
    GROUP BY  hour_bucket, yr
), yearly_avg AS (    /* average hourly total for each year */
    SELECT
        yr,
        AVG(hour_total_value)           AS avg_hour_value
    FROM hourly
    GROUP BY yr
)
SELECT
      y20.avg_hour_value   -  y19.avg_hour_value     AS diff_avg_hour_value_2020_minus_2019
FROM  (SELECT avg_hour_value FROM yearly_avg WHERE yr = 2019) y19,
      (SELECT avg_hour_value FROM yearly_avg WHERE yr = 2020) y20;