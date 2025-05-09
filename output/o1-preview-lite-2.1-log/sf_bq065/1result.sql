SELECT
    s.value::STRING AS "Symbol",
    ROUND(
        r.value::FLOAT / TRY_TO_NUMBER(PARSE_JSON(PARSE_JSON("decoded_result")['calldata'])['multiplier']::STRING),
        4
    ) AS "Rate"
FROM
    "CRYPTO"."CRYPTO_BAND"."ORACLE_REQUESTS",
    LATERAL FLATTEN(INPUT => PARSE_JSON(PARSE_JSON("decoded_result")['calldata'])['symbols']) s,
    LATERAL FLATTEN(INPUT => PARSE_JSON(PARSE_JSON("decoded_result")['result'])['rates']) r
WHERE
    s.seq = r.seq
    AND TRY_TO_NUMBER(PARSE_JSON("request")['oracle_script_id']::VARCHAR) = 3
ORDER BY
    TO_TIMESTAMP_NTZ("block_timestamp") DESC NULLS LAST
LIMIT 10;