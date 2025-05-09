WITH "filtered" AS (
    SELECT
        TO_TIMESTAMP("block_timestamp" / 1000000)           AS "ts",
        TRY_TO_NUMBER("value")                              AS "value"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN 1546300800000000  -- 2019‑01‑01
                              AND 1609459199000000  -- 2020‑12‑31
),
"hourly" AS (
    SELECT
        DATE_TRUNC('HOUR', "ts")  AS "hour_bucket",
        SUM("value")              AS "hour_sum"
    FROM "filtered"
    GROUP BY "hour_bucket"
),
"delta" AS (
    SELECT
        "hour_bucket",
        ABS("hour_sum" - LAG("hour_sum") OVER (ORDER BY "hour_bucket")) AS "hourly_delta"
    FROM "hourly"
),
"yearly" AS (
    SELECT
        EXTRACT(YEAR FROM "hour_bucket") AS "year",
        AVG("hourly_delta")              AS "avg_hourly_delta"
    FROM "delta"
    GROUP BY "year"
)
SELECT
    ROUND(
        (SELECT "avg_hourly_delta" FROM "yearly" WHERE "year" = 2020) -
        (SELECT "avg_hourly_delta" FROM "yearly" WHERE "year" = 2019)
    , 4) AS "avg_hourly_change_difference";