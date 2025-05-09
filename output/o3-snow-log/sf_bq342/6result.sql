WITH tx AS (
    SELECT 
        /* convert micro-seconds to TIMESTAMP (no time-zone) */
        TO_TIMESTAMP_NTZ("block_timestamp"/1000000)           AS ts ,
        TO_NUMBER("value")                                    AS token_value
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND ( LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      AND  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp"/1000000))
           BETWEEN '2019-01-01' AND '2020-12-31'
),
hourly AS (
    /* total transferred each hour */
    SELECT 
        DATE_TRUNC('HOUR', ts)          AS hour_ts ,
        SUM(token_value)                AS hourly_value
    FROM tx
    GROUP BY hour_ts
),
yearly_avg AS (
    /* average of the hourly totals for each year */
    SELECT 
        EXTRACT(YEAR FROM hour_ts)      AS yr ,
        AVG(hourly_value)               AS avg_hourly_value
    FROM hourly
    GROUP BY yr
    HAVING yr IN (2019, 2020)
)
SELECT
    MAX(CASE WHEN yr = 2019 THEN avg_hourly_value END)                 AS "avg_hourly_2019",
    MAX(CASE WHEN yr = 2020 THEN avg_hourly_value END)                 AS "avg_hourly_2020",
    MAX(CASE WHEN yr = 2020 THEN avg_hourly_value END)
    - MAX(CASE WHEN yr = 2019 THEN avg_hourly_value END)               AS "difference_2020_minus_2019"
FROM yearly_avg;