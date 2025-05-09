WITH  filtered AS (
        SELECT
            TO_TIMESTAMP( "block_timestamp" / 1000000 )           AS "ts",
            CAST( "value" AS NUMBER(38,0) )                       AS "value_dec"
        FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
        WHERE  "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
          AND ( "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
             OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f' )
          AND  TO_TIMESTAMP( "block_timestamp" / 1000000 ) >= '2019-01-01'
          AND  TO_TIMESTAMP( "block_timestamp" / 1000000 ) <  '2021-01-01'
),  per_hour AS (
        SELECT
            DATE_TRUNC( 'HOUR', "ts" )          AS "hour_ts",
            SUM( "value_dec" )                  AS "hour_value"
        FROM   filtered
        GROUP  BY "hour_ts"
),  per_hour_change AS (
        SELECT
            "hour_ts",
            "hour_value",
            "hour_value"
          - LAG( "hour_value" ) OVER ( ORDER BY "hour_ts" )  AS "change_value"
        FROM   per_hour
),  per_year AS (
        SELECT
            EXTRACT( YEAR FROM "hour_ts" )      AS "yr",
            AVG( "change_value" )               AS "avg_hourly_change"
        FROM   per_hour_change
        WHERE  "change_value" IS NOT NULL
        GROUP  BY "yr"
        HAVING "yr" IN ( 2019, 2020 )
)
SELECT
    MAX( CASE WHEN "yr" = 2020 THEN "avg_hourly_change" END )
  - MAX( CASE WHEN "yr" = 2019 THEN "avg_hourly_change" END )   AS "diff_avg_hourly_change_2020_minus_2019"
FROM   per_year;