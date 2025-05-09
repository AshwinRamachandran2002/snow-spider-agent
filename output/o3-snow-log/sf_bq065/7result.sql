WITH top_requests AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND."ORACLE_REQUESTS"
    WHERE PARSE_JSON("request"):"oracle_script_id"::NUMBER = 3          -- keep only script-ID 3
      AND "decoded_result" IS NOT NULL                                  -- need decoded data
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10                                                            -- newest 10 requests
)

SELECT
    tr."block_timestamp",
    tr."oracle_request_id",
    sym.value::STRING                                                               AS "symbol",
    (
        rate.value::NUMBER /
        PARSE_JSON(tr."decoded_result":"calldata"::STRING):"multiplier"::NUMBER
    )                                                                               AS "adjusted_rate"
FROM top_requests  tr,
     LATERAL FLATTEN(
         input => PARSE_JSON(tr."decoded_result":"calldata"::STRING):"symbols"
     ) sym,
     LATERAL FLATTEN(
         input => PARSE_JSON(tr."decoded_result":"result"  ::STRING):"rates"
     ) rate
WHERE sym.index = rate.index                                                        -- align symbol ↔ rate
ORDER BY tr."block_timestamp_truncated" DESC,                                        -- newest first
         tr."oracle_request_id" DESC,
         sym.index;