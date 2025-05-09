WITH filtered_transfers AS (
    SELECT
        DATE_TRUNC(
            'hour',
            TO_TIMESTAMP("block_timestamp" / 1000000)
        )                                  AS "hour_ts",
        TO_NUMBER("value")                  AS "token_value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR LOWER("to_address")   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN
            DATE_PART(epoch_second , TO_TIMESTAMP('2019-01-01T00:00:00Z')) * 1000000
        AND DATE_PART(epoch_second , TO_TIMESTAMP('2020-12-31T23:59:59Z')) * 1000000
),
hourly_totals AS (
    SELECT
        "hour_ts",
        SUM("token_value") AS "hour_value"
    FROM filtered_transfers
    GROUP BY "hour_ts"
),
hourly_changes AS (
    SELECT
        "hour_ts",
        "hour_value" - LAG("hour_value") OVER (ORDER BY "hour_ts") AS "hour_change"
    FROM hourly_totals
),
avg_change_per_year AS (
    SELECT
        EXTRACT(year FROM "hour_ts") AS "year",
        AVG("hour_change")           AS "avg_hourly_change"
    FROM hourly_changes
    WHERE "hour_change" IS NOT NULL          -- exclude first hour which has no previous hour
    GROUP BY EXTRACT(year FROM "hour_ts")
)
SELECT
    (SELECT "avg_hourly_change" FROM avg_change_per_year WHERE "year" = 2020) -
    (SELECT "avg_hourly_change" FROM avg_change_per_year WHERE "year" = 2019) AS "difference_avg_hourly_change_2020_minus_2019";