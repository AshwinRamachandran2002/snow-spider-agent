WITH recent_requests AS (
    SELECT
        "block_timestamp",
        "block_timestamp_truncated",
        "oracle_request_id",
        PARSE_JSON("decoded_result") AS decoded -- keep decoded_result parsed once
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::INTEGER = 3
    ORDER BY "block_timestamp_truncated" DESC NULLS LAST
    LIMIT 10
)

SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                           AS "symbol",
    rate.value::NUMBER 
      / NULLIF( PARSE_JSON(r.decoded:"calldata"):"multiplier"::NUMBER , 0) 
                                                               AS "adjusted_rate"
FROM   recent_requests r
       , LATERAL FLATTEN( input => PARSE_JSON(r.decoded:"calldata"):"symbols") sym
       , LATERAL FLATTEN( input => PARSE_JSON(r.decoded:"result"):"rates")     rate
WHERE  sym.index = rate.index          -- align symbol with its corresponding rate
ORDER  BY r."block_timestamp_truncated" DESC NULLS LAST,
          r."oracle_request_id",
          sym.index;