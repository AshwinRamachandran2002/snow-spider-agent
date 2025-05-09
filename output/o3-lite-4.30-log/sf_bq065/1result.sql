WITH recent_requests AS (
    SELECT
        *,
        PARSE_JSON("decoded_result":"calldata"::STRING):"multiplier"::FLOAT AS "multiplier"
    FROM "CRYPTO"."CRYPTO_BAND"."ORACLE_REQUESTS"
    WHERE "request":"oracle_script_id"::INT = 3
    ORDER BY "block_timestamp" DESC
    LIMIT 10
)
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING AS "symbol",
    ROUND( rat.value::FLOAT / NULLIF(r."multiplier", 0), 4 ) AS "adjusted_rate"
FROM recent_requests r
     ,LATERAL FLATTEN(
         input => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
       ) sym
     ,LATERAL FLATTEN(
         input => PARSE_JSON(r."decoded_result":"result"::STRING):"rates"
       ) rat
WHERE sym.index = rat.index
ORDER BY r."block_timestamp" DESC, r."oracle_request_id", sym.index;