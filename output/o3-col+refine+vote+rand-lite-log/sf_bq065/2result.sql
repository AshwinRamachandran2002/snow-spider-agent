WITH latest_requests AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::INTEGER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)
SELECT
    lr."block_timestamp"                              AS "block_timestamp",
    lr."oracle_request_id"                            AS "oracle_request_id",
    sym.value::STRING                                 AS "symbol",
    rate.value::NUMBER 
      / NULLIF(cd."multiplier"::NUMBER, 0)            AS "adjusted_rate"
FROM   latest_requests AS lr
       -- parse calldata once to extract symbols array & multiplier
       , LATERAL (
           SELECT PARSE_JSON(lr."decoded_result":"calldata"::STRING) AS calldata
         ) AS cal
       , LATERAL (
           SELECT cal.calldata:"multiplier" AS "multiplier"
         ) AS cd
       -- flatten symbols & rates arrays
       , LATERAL FLATTEN(
           input => cal.calldata:"symbols"
         ) AS sym
       , LATERAL FLATTEN(
           input => PARSE_JSON(lr."decoded_result":"result"::STRING):"rates"
         ) AS rate
WHERE  sym.index = rate.index          -- align each symbol with its corresponding rate
ORDER BY lr."block_timestamp_truncated" DESC NULLS LAST,
         sym.index;