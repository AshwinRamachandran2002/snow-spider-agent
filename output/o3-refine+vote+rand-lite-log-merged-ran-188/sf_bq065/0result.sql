WITH recent_requests AS (   -- 10 newest oracle_script_id = 3
    SELECT
        "block_timestamp",
        "oracle_request_id",
        PARSE_JSON("decoded_result":"calldata"::STRING) AS cal_json,
        PARSE_JSON("decoded_result":"result"::STRING)   AS res_json
    FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE "request":"oracle_script_id"::INT = 3
    ORDER BY "block_timestamp_truncated" DESC
    LIMIT 10
),
symbols AS (                -- explode symbols array
    SELECT
        r."block_timestamp",
        r."oracle_request_id",
        f.index                              AS pos,
        f.value::STRING                      AS symbol,
        r.cal_json:"multiplier"::NUMBER      AS multiplier
    FROM recent_requests r,
         LATERAL FLATTEN(input => r.cal_json:"symbols") f
),
rates AS (                  -- explode rates array
    SELECT
        r."oracle_request_id",
        f.index               AS pos,
        f.value::NUMBER       AS raw_rate
    FROM recent_requests r,
         LATERAL FLATTEN(input => r.res_json:"rates") f
)
SELECT
    s."block_timestamp",
    s."oracle_request_id",
    s.symbol,
    rates.raw_rate / s.multiplier            AS adjusted_rate
FROM symbols s
JOIN rates
  ON s."oracle_request_id" = rates."oracle_request_id"
 AND s.pos               = rates.pos
ORDER BY s."block_timestamp" DESC NULLS LAST,   -- newest first
         s."oracle_request_id",
         s.pos;