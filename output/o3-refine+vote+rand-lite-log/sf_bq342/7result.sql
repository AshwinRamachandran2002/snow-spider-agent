WITH "FILTERED_TRANSFERS" AS (
    SELECT
        /* convert micro‑seconds to TIMESTAMP */
        TO_TIMESTAMP("block_timestamp"/1e6)                                   AS "TS",
        /* token amount is stored as TEXT – cast to DECIMAL */
        TO_DECIMAL("value")                                                   AS "TOKEN_VALUE"
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (  LOWER("from_address") = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
          OR LOWER("to_address") = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f' )
      AND   TO_DATE(TO_TIMESTAMP("block_timestamp"/1e6)) 
            BETWEEN '2019-01-01' AND '2020-12-31'
), "HOURLY_TOTALS" AS (
    /* total transferred per hour */
    SELECT
        DATE_TRUNC('hour', "TS")                         AS "HOUR_TS",
        SUM("TOKEN_VALUE")                               AS "HOURLY_VALUE"
    FROM   "FILTERED_TRANSFERS"
    GROUP  BY 1
), "YEARLY_AVERAGE" AS (
    /* average hourly total for each calendar year */
    SELECT
        EXTRACT(year FROM "HOUR_TS")                     AS "YEAR",
        AVG("HOURLY_VALUE")                              AS "AVG_HOURLY_VALUE"
    FROM   "HOURLY_TOTALS"
    GROUP  BY 1
    HAVING "YEAR" IN (2019, 2020)
)
SELECT
    MAX(CASE WHEN "YEAR" = 2020 THEN "AVG_HOURLY_VALUE" END)
  - MAX(CASE WHEN "YEAR" = 2019 THEN "AVG_HOURLY_VALUE" END)  AS "AVG_HOURLY_VALUE_DIFF_2020_MINUS_2019"
FROM "YEARLY_AVERAGE";