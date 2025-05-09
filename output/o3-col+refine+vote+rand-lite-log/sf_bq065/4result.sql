WITH recent_reqs AS (
    SELECT *
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::NUMBER = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
)
SELECT
       r."block_timestamp",
       r."oracle_request_id",
       sym.value::STRING                                                          AS "symbol",
       (rate.value::NUMBER
        / PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier"::NUMBER) AS "adjusted_rate"
FROM   recent_reqs AS r
       , LATERAL FLATTEN(
             input => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
         ) AS sym
       , LATERAL FLATTEN(
             input => PARSE_JSON(r."decoded_result":"result"::STRING):"rates"
         ) AS rate
WHERE  sym.index = rate.index
ORDER  BY r."block_timestamp_truncated" DESC,
          r."oracle_request_id",
          sym.index;