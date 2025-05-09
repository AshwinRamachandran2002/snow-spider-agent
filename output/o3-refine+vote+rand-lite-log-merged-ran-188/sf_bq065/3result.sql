WITH latest_requests AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                                        AS "symbol",
    rt.value::NUMBER
      / PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier"::NUMBER
                                                                              AS "adjusted_rate"
FROM latest_requests r,
     LATERAL FLATTEN(
         INPUT => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
     ) sym,
     LATERAL FLATTEN(
         INPUT => PARSE_JSON(r."decoded_result":"result"::STRING):"rates"
     ) rt
WHERE sym.index = rt.index
ORDER BY r."block_timestamp_truncated" DESC NULLS LAST;