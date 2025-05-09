-- 10 most-recent oracle requests (script_id = 3)  
-- Return symbol-rate pairs with rate adjusted by multiplier
SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                                   AS "symbol",
    rt.value::NUMBER
      / PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier"::NUMBER
                                                                          AS "adjusted_rate"
FROM (
        /* grab the 10 newest requests first */
        SELECT *
        FROM CRYPTO.CRYPTO_BAND."ORACLE_REQUESTS"
        WHERE  "request":"oracle_script_id"::NUMBER = 3
          AND  "decoded_result" IS NOT NULL
        ORDER BY "block_timestamp_truncated" DESC
        LIMIT 10
     ) AS r
     /* symbols array */
     , LATERAL FLATTEN(
           INPUT => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
       ) AS sym
     /* rates array */
     , LATERAL FLATTEN(
           INPUT => PARSE_JSON(r."decoded_result":"result"::STRING):"rates"
       ) AS rt
WHERE sym.index = rt.index                    -- align symbol with its rate
ORDER BY r."block_timestamp" DESC NULLS LAST, -- newest requests first
         r."oracle_request_id" DESC,
         sym.index;