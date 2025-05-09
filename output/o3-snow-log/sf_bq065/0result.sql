/* 10 most-recent oracle_script_id = 3 requests –
   explode symbols & rates, adjust by multiplier  */
WITH recent AS (
    SELECT  *
    FROM    CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE   "request":"oracle_script_id" = 3
    ORDER BY "block_height" DESC
    LIMIT   10
)

SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                                AS "symbol",
    rate.value::FLOAT
          / NULLIF( PARSE_JSON(r."decoded_result":"calldata"):"multiplier"::FLOAT , 0 )  AS "adjusted_rate"
FROM    recent r,
        LATERAL FLATTEN( INPUT => PARSE_JSON(r."decoded_result":"calldata"):"symbols" ) sym,
        LATERAL FLATTEN( INPUT => PARSE_JSON(r."decoded_result":"result"):"rates"   ) rate
WHERE   sym.index = rate.index            -- align symbol with its rate
ORDER BY r."block_timestamp" DESC NULLS LAST,
         r."oracle_request_id",
         "symbol";