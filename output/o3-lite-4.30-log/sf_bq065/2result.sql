WITH last_10_requests AS (
    SELECT
        "oracle_request_id",
        "block_timestamp",
        "block_timestamp_truncated",
        "decoded_result"
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)
SELECT
    r."block_timestamp"                                           AS "block_timestamp",
    r."oracle_request_id"                                         AS "oracle_request_id",
    sym.value::STRING                                             AS "symbol",
    ROUND(
        rate.value::NUMBER
        / NULLIF(
              PARSE_JSON(r."decoded_result":"calldata"):"multiplier"::NUMBER,
              0
          ),
        4
    )                                                             AS "adjusted_rate"
FROM   last_10_requests r
CROSS JOIN LATERAL FLATTEN(
                 input => PARSE_JSON(r."decoded_result":"calldata"):"symbols"
             ) sym
CROSS JOIN LATERAL FLATTEN(
                 input => PARSE_JSON(r."decoded_result":"result"):"rates"
             ) rate
WHERE  rate.index = sym.index
ORDER  BY r."block_timestamp_truncated" DESC,
          sym.index;