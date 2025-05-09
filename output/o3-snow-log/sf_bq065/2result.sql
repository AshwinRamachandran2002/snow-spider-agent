-- 10 newest oracle_script_id = 3 requests, expand symbols & compute adjusted rates
WITH latest_reqs AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC NULLS LAST
    LIMIT 10
)
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    f.value::STRING                                                     AS "symbol",
    (
        PARSE_JSON(r."decoded_result":"result"::STRING):"rates"[f.index]::NUMBER
        / NULLIF(
              PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier"::NUMBER,
              0
          )
    )                                                                   AS "adjusted_rate"
FROM latest_reqs r,
     LATERAL FLATTEN(
         INPUT => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
     ) f
ORDER BY r."block_timestamp_truncated" DESC NULLS LAST;