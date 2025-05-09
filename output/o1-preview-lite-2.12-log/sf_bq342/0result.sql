WITH filtered_data AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "year",
        EXTRACT(hour FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "hour",
        SUM(TRY_TO_NUMBER("value")) AS "total_value"
    FROM
        CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE
        "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d' OR
            "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) BETWEEN '2019-01-01' AND '2020-12-31 23:59:59'
    GROUP BY
        EXTRACT(year FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)),
        EXTRACT(hour FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
),
hourly_changes AS (
    SELECT
        "year",
        "hour",
        "total_value",
        LAG("total_value") OVER (PARTITION BY "year" ORDER BY "hour") AS "previous_total_value",
        ABS("total_value" - LAG("total_value") OVER (PARTITION BY "year" ORDER BY "hour")) AS "hourly_change"
    FROM
        filtered_data
),
average_changes AS (
    SELECT
        "year",
        AVG("hourly_change") AS "avg_hourly_change"
    FROM
        hourly_changes
    WHERE
        "previous_total_value" IS NOT NULL
    GROUP BY
        "year"
)
SELECT
    ROUND(ABS(
        (SELECT "avg_hourly_change" FROM average_changes WHERE "year" = 2020) -
        (SELECT "avg_hourly_change" FROM average_changes WHERE "year" = 2019)
    ), 4) AS "difference_in_average_hourly_change";