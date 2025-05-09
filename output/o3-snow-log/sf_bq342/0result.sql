WITH filtered AS (
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))  AS "hour_ts",
        TO_NUMBER("value")                                             AS "txn_value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR LOWER("to_address") = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      AND  "block_timestamp" BETWEEN 1546300800000000     -- 2019-01-01 00:00:00 UTC
                                 AND 1609459199000000     -- 2020-12-31 23:59:59 UTC
), hourly AS (                          -- total transferred each hour
    SELECT
        "hour_ts",
        SUM("txn_value") AS "hourly_total_value"
    FROM filtered
    GROUP BY "hour_ts"
), yearly_avg AS (                      -- average hourly total per calendar year
    SELECT
        YEAR("hour_ts")      AS "yr",
        AVG("hourly_total_value") AS "avg_hourly_value"
    FROM hourly
    GROUP BY "yr"
    HAVING "yr" IN (2019, 2020)
)
SELECT
    MAX(CASE WHEN "yr" = 2019 THEN "avg_hourly_value" END) AS "avg_hourly_value_2019",
    MAX(CASE WHEN "yr" = 2020 THEN "avg_hourly_value" END) AS "avg_hourly_value_2020",
    MAX(CASE WHEN "yr" = 2020 THEN "avg_hourly_value" END)
      - MAX(CASE WHEN "yr" = 2019 THEN "avg_hourly_value" END) AS "difference_2020_minus_2019"
FROM yearly_avg;