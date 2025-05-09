/*  Same logic, lighter operators:
    • use TO_NUMBER (fast) instead of TO_DECIMAL
    • avoid TIMESTAMP casts entirely
    • aggregate on integer hour-bucket                                */

WITH base AS (            -- rows for the token / addresses inside 2019-2020
    SELECT
        "block_timestamp",                       -- micro-seconds since epoch
        TO_NUMBER("value")  AS "val"             -- convert once, cheap
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
              "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN 1546300800000000    -- 2019-01-01 00:00:00
                              AND 1609459199000000      -- 2020-12-31 23:59:59
),
hourly_totals AS (        -- summed token value per hour (integer bucket) & per year
    SELECT
        FLOOR("block_timestamp" / 3600000000)                 AS "hr_bucket_int",
        CASE
            WHEN "block_timestamp" < 1577836800000000 THEN 2019  -- < 2020-01-01
            ELSE 2020
        END                                                   AS "yr",
        SUM("val")                                            AS "hour_val"
    FROM base
    GROUP BY 1, 2
),
hourly_diffs AS (         -- abs change vs previous hour inside each year
    SELECT
        "yr",
        ABS(
            "hour_val"
          - LAG("hour_val") OVER (PARTITION BY "yr" ORDER BY "hr_bucket_int")
        )                                   AS "diff_val"
    FROM hourly_totals
),
avg_change AS (           -- average hourly change per year
    SELECT
        "yr",
        AVG("diff_val")   AS "avg_hourly_change"
    FROM hourly_diffs
    WHERE "diff_val" IS NOT NULL
    GROUP BY "yr"
)
SELECT
      (SELECT "avg_hourly_change" FROM avg_change WHERE "yr" = 2020)
    - (SELECT "avg_hourly_change" FROM avg_change WHERE "yr" = 2019)
      AS "difference_avg_hourly_changes_2020_minus_2019";