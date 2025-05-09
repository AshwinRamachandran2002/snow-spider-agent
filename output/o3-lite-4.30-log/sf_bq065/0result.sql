WITH recent_requests AS (
    SELECT *
    FROM "CRYPTO"."CRYPTO_BAND"."ORACLE_REQUESTS"
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    s.value::STRING                                                               AS symbol,
    ROUND(
        rt.value::NUMBER /
        NULLIF(cal.cal_json:"multiplier"::NUMBER, 0),
        4
    )                                                                             AS adjusted_rate
FROM recent_requests r
     CROSS JOIN LATERAL (
         SELECT PARSE_JSON(r."decoded_result":"calldata") AS cal_json
     ) cal
     , LATERAL FLATTEN(input => cal.cal_json:"symbols")                                  s
     , LATERAL FLATTEN(input => PARSE_JSON(r."decoded_result":"result"):"rates")         rt
WHERE s.index = rt.index
ORDER BY r."block_timestamp_truncated" DESC,
         r."oracle_request_id",
         s.index;