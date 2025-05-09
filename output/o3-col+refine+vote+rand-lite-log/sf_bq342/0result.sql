WITH filtered_transfers AS (   -- token movements that match the address-side filter
    SELECT
        FLOOR("block_timestamp" / 3600000000)          AS hr_slot,   -- 1-hour buckets
        "block_timestamp",
        TRY_TO_NUMBER("value")                         AS val,
        CASE
            WHEN "block_timestamp" < 1577836800000000  -- 2020-01-01 00:00:00 UTC
                 THEN '2019'
            ELSE '2020'
        END                                            AS yr
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
          )
      AND "block_timestamp" BETWEEN 1546300800000000               -- 2019-01-01
                               AND 1609459199000000               -- 2020-12-31 23:59:59
),
hourly_totals AS (             -- total transferred value per hour, per year
    SELECT
        yr,
        hr_slot,
        SUM(val) AS hour_value
    FROM filtered_transfers
    GROUP BY yr, hr_slot
),
hourly_deltas AS (             -- |Δ| from previous hour inside each year
    SELECT
        yr,
        ABS(hour_value
            - LAG(hour_value) OVER (PARTITION BY yr ORDER BY hr_slot)
           ) AS abs_delta
    FROM hourly_totals
),
average_change AS (            -- average absolute hourly change per year
    SELECT
        yr,
        AVG(abs_delta) AS avg_hourly_change
    FROM hourly_deltas
    WHERE abs_delta IS NOT NULL          -- skip the first hour (no previous value)
    GROUP BY yr
)
SELECT
    MAX(CASE WHEN yr = '2019' THEN avg_hourly_change END) AS "avg_change_2019",
    MAX(CASE WHEN yr = '2020' THEN avg_hourly_change END) AS "avg_change_2020",
    MAX(CASE WHEN yr = '2020' THEN avg_hourly_change END)
      - MAX(CASE WHEN yr = '2019' THEN avg_hourly_change END) AS "difference_2020_minus_2019"
FROM average_change;