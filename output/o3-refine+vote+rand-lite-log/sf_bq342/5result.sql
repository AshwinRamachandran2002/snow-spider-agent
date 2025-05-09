WITH base AS (
    SELECT
        DATE_TRUNC(
            'HOUR',
            TO_TIMESTAMP("block_timestamp" / 1e6)
        )                                 AS hour_ts,
        TO_NUMBER("value")                AS tx_value
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE
        LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
                LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
             OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_TIMESTAMP("block_timestamp" / 1e6)
                BETWEEN '2019-01-01' AND '2020-12-31 23:59:59'
),
hourly AS (
    SELECT
        hour_ts,
        SUM(tx_value)            AS hour_total
    FROM base
    GROUP BY hour_ts
),
changes AS (
    SELECT
        hour_ts,
        ABS(hour_total
            - LAG(hour_total) OVER (ORDER BY hour_ts)) AS hour_change
    FROM hourly
),
yearly_avg AS (
    SELECT
        YEAR(hour_ts)               AS yr,
        AVG(hour_change)            AS avg_hour_change
    FROM changes
    WHERE hour_change IS NOT NULL      -- remove the first hour (no previous)
    GROUP BY YEAR(hour_ts)
    HAVING yr IN (2019, 2020)
)
SELECT
    MAX(CASE WHEN yr = 2020 THEN avg_hour_change END)
      - MAX(CASE WHEN yr = 2019 THEN avg_hour_change END)   AS diff_avg_hour_change_2020_minus_2019
FROM yearly_avg;