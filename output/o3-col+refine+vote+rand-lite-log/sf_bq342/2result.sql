WITH transfers AS (
    SELECT
        TO_TIMESTAMP("block_timestamp"/1e6)                               AS ts,
        YEAR(TO_TIMESTAMP("block_timestamp"/1e6))                         AS yr,
        "value"::NUMBER                                                   AS val
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND  ( "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
             OR "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f' )
      AND  "block_timestamp" BETWEEN 1546300800000000   -- 2019-01-01
                                AND     1609459199000000 -- 2020-12-31
),
hourly AS (
    SELECT
        DATE_TRUNC('hour', ts)                                 AS hr,
        yr,
        SUM(val)                                               AS hr_val
    FROM   transfers
    GROUP  BY yr, hr
),
diffs AS (
    SELECT
        yr,
        ABS(hr_val - LAG(hr_val) OVER (PARTITION BY yr ORDER BY hr)) AS delta
    FROM   hourly
),
avg_deltas AS (
    SELECT
        yr,
        AVG(delta) AS avg_delta
    FROM   diffs
    WHERE  delta IS NOT NULL
    GROUP  BY yr
)
SELECT
    MAX(CASE WHEN yr = 2020 THEN avg_delta END)
  - MAX(CASE WHEN yr = 2019 THEN avg_delta END) AS diff_avg_hourly_change
FROM avg_deltas;