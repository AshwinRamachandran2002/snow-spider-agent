WITH filtered_transfers AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)                               AS "ts",
        TRY_CAST("value" AS NUMBER(38,0))                                       AS "value_int"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE
        "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
                "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
             OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_TIMESTAMP("block_timestamp" / 1000000) BETWEEN
            '2019-01-01 00:00:00' AND '2020-12-31 23:59:59'
),
hourly_totals AS (
    SELECT
        DATE_TRUNC('hour', "ts")                       AS "hour_ts",
        SUM("value_int")                               AS "hour_value"
    FROM filtered_transfers
    GROUP BY DATE_TRUNC('hour', "ts")
),
hourly_changes AS (
    SELECT
        "hour_ts",
        YEAR("hour_ts")                                AS "yr",
        "hour_value" -
        LAG("hour_value") OVER (ORDER BY "hour_ts")    AS "hour_change"
    FROM hourly_totals
)
SELECT
      AVG(CASE WHEN "yr" = 2020 THEN "hour_change" END) 
    - AVG(CASE WHEN "yr" = 2019 THEN "hour_change" END) AS "difference_avg_hourly_change_2020_minus_2019"
FROM hourly_changes
WHERE "yr" IN (2019, 2020);