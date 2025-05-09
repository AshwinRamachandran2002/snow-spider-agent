WITH recent_requests AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC NULLS LAST
    LIMIT 10
)
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    s.value::STRING                                                 AS "symbol",
    r8.value::NUMBER
        / PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier"::NUMBER
                                                                      AS "adjusted_rate"
FROM recent_requests r
     , LATERAL FLATTEN(
           input => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
       ) s
     , LATERAL FLATTEN(
           input => PARSE_JSON(r."decoded_result":"result"::STRING):"rates"
       ) r8
WHERE s.index = r8.index
ORDER BY
    r."block_timestamp_truncated" DESC NULLS LAST,
    r."oracle_request_id"        DESC,
    s.index;