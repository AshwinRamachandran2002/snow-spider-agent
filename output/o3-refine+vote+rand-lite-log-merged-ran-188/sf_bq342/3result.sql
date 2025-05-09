WITH filtered_transfers AS (
    SELECT
        DATE_TRUNC(
            'hour',
            TO_TIMESTAMP("block_timestamp" / 1e6)      -- convert µs -> TIMESTAMP
        )                                                   AS "hour_ts",
        CAST("value" AS NUMBER(38,0))                       AS "value_num"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE
        "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
                "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
             OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))
              BETWEEN '2019-01-01' AND '2020-12-31'
), 

hourly_totals AS (
    SELECT
        "hour_ts",
        SUM("value_num") AS "hour_total"
    FROM filtered_transfers
    GROUP BY "hour_ts"
), 

hourly_changes AS (
    SELECT
        "hour_ts",
        ABS("hour_total" - LAG("hour_total") OVER (ORDER BY "hour_ts"))
            AS "hour_change"
    FROM hourly_totals
), 

avg_changes_per_year AS (
    SELECT
        YEAR("hour_ts")                             AS "year",
        AVG("hour_change")                          AS "avg_hour_change"
    FROM hourly_changes
    WHERE "hour_change" IS NOT NULL
    GROUP BY YEAR("hour_ts")
    HAVING "year" IN (2019, 2020)
) 

SELECT
    MAX(CASE WHEN "year" = 2020 THEN "avg_hour_change" END)
  - MAX(CASE WHEN "year" = 2019 THEN "avg_hour_change" END)
        AS "diff_avg_hour_change_2020_minus_2019"
FROM avg_changes_per_year;