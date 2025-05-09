WITH recent_requests AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::INTEGER = 3
    ORDER BY "block_timestamp_truncated" DESC NULLS LAST
    LIMIT 10
)

SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.VALUE::STRING AS "symbol",
    (
        PARSE_JSON(r."decoded_result":"result"::STRING ):"rates"[ sym.INDEX ]::NUMBER
        /
        PARSE_JSON(r."decoded_result":"calldata"::STRING ):"multiplier"::NUMBER
    ) AS "adjusted_rate"
FROM recent_requests r,
     LATERAL FLATTEN(
         INPUT => PARSE_JSON(r."decoded_result":"calldata"::STRING ):"symbols"
     ) sym
ORDER BY
    r."block_timestamp_truncated" DESC NULLS LAST,
    r."oracle_request_id",
    sym.INDEX;