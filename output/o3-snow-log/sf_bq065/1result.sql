/* 10 most-recent oracle_script_id = 3 requests –
   explode symbols & rates, scale each rate by its multiplier           */

WITH latest_requests AS (
    SELECT
        "oracle_request_id",
        "block_timestamp",
        /* decode the JSON-encoded strings inside `decoded_result` */
        PARSE_JSON("decoded_result":"calldata")        AS cl,   -- contains symbols[] & multiplier
        PARSE_JSON("decoded_result":"result")          AS rs    -- contains rates[]
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
          AND "decoded_result" IS NOT NULL
    ORDER BY "block_timestamp" DESC NULLS LAST
    LIMIT 10
)

SELECT
    lr."block_timestamp",
    lr."oracle_request_id",
    sym.value::STRING                                                        AS "symbol",
    (rate.value::NUMBER / NULLIF(lr.cl:"multiplier"::NUMBER,0))              AS "adjusted_rate"
FROM latest_requests lr
     , LATERAL FLATTEN(input => lr.cl:"symbols") sym
     , LATERAL FLATTEN(input => lr.rs:"rates")   rate
WHERE sym.index = rate.index                           -- pair symbols & rates by position
ORDER BY lr."block_timestamp" DESC NULLS LAST,         -- newest requests first
         lr."oracle_request_id",
         sym.index;