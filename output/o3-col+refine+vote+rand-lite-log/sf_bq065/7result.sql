WITH recent AS (
    /* 10 most-recent oracle requests that use oracle_script_id = 3 */
    SELECT
        "block_timestamp_truncated",
        "oracle_request_id",
        PARSE_JSON("decoded_result")        AS decoded_json
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)

SELECT
    r."block_timestamp_truncated"                                      AS "block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                                  AS "symbol",
    rt.value::NUMBER
        / PARSE_JSON(r.decoded_json:"calldata"):"multiplier"::NUMBER   AS "adjusted_rate"
FROM recent AS r
     /* explode symbols array coming from the calldata JSON */
     , LATERAL FLATTEN(
         INPUT => PARSE_JSON(r.decoded_json:"calldata"):"symbols"
       ) AS sym
     /* explode rates array coming from the result JSON */
     , LATERAL FLATTEN(
         INPUT => PARSE_JSON(r.decoded_json:"result"):"rates"
       ) AS rt
WHERE sym.index = rt.index                          -- align each symbol with its rate
ORDER BY r."block_timestamp_truncated" DESC,        -- newest first
         r."oracle_request_id",
         sym.index;