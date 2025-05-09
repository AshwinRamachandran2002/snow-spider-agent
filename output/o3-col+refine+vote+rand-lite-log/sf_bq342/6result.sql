/* Difference in average hourly transaction value (2020 − 2019) */
WITH filtered AS (   -- all transfers that meet token & address criteria
    SELECT
        "block_timestamp",
        "value"::FLOAT  AS "value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
),
h19 AS (               -- hourly aggregates for 2019
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp"/1e6)) AS "hr",
        SUM("value")                                          AS "hourly_value"
    FROM filtered
    WHERE "block_timestamp"
          BETWEEN 1546300800000000      -- 2019-01-01 00:00:00
              AND 1577836799000000      -- 2019-12-31 23:59:59
    GROUP BY "hr"
),
h20 AS (               -- hourly aggregates for 2020
    SELECT
        DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp"/1e6)) AS "hr",
        SUM("value")                                          AS "hourly_value"
    FROM filtered
    WHERE "block_timestamp"
          BETWEEN 1577836800000000      -- 2020-01-01 00:00:00
              AND 1609459199000000      -- 2020-12-31 23:59:59
    GROUP BY "hr"
),
avg19 AS (SELECT AVG("hourly_value") AS "avg_2019" FROM h19),
avg20 AS (SELECT AVG("hourly_value") AS "avg_2020" FROM h20)

SELECT
    avg20."avg_2020" - avg19."avg_2019" AS "avg_hourly_difference_2020_minus_2019"
FROM avg19, avg20;