WITH transfers AS (   -- all token transfers that meet the requirements
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1e6))  AS "hour_ts",
        CAST("value" AS NUMBER(38,0))                              AS "token_value"
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND ( LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
            OR LOWER("to_address") = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f' )
      AND  TO_TIMESTAMP("block_timestamp" / 1e6) >= '2019-01-01'            -- inclusive
      AND  TO_TIMESTAMP("block_timestamp" / 1e6) <  '2021-01-01'            -- up-to but not incl. 2021
),
hourly_totals AS (     -- total value per hour
    SELECT
        "hour_ts",
        SUM("token_value") AS "hour_value"
    FROM   transfers
    GROUP  BY "hour_ts"
),
hourly_changes AS (    -- absolute change versus the previous hour
    SELECT
        "hour_ts",
        ABS("hour_value" - LAG("hour_value") OVER (ORDER BY "hour_ts")) AS "hour_change",
        EXTRACT(year FROM "hour_ts")                                     AS "year"
    FROM   hourly_totals
),
avg_changes AS (       -- average hourly change for each year
    SELECT
        "year",
        AVG("hour_change") AS "avg_hour_change"
    FROM   hourly_changes
    WHERE  "hour_change" IS NOT NULL
      AND  "year" IN (2019, 2020)
    GROUP  BY "year"
)
SELECT
    MAX(CASE WHEN "year" = 2020 THEN "avg_hour_change" END) -
    MAX(CASE WHEN "year" = 2019 THEN "avg_hour_change" END)  AS "difference_avg_hourly_change_2020_minus_2019"
FROM   avg_changes;