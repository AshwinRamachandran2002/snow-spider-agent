/* Symbol-rate pairs (rate adjusted by multiplier) for the 10 most-recent
   Band oracle requests whose oracle_script_id = 3                       */

WITH latest_requests AS (
    SELECT *
    FROM   CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
    WHERE  COALESCE(                                           -- script-ID may live in either column
              "oracle_script":"oracle_script_id"::INT,
              "request":"oracle_script_id"::INT
           ) = 3
      AND  "decoded_result" IS NOT NULL                        -- ensures symbols & rates exist
    ORDER  BY "block_timestamp_truncated" DESC
    LIMIT  10
)

SELECT
    lr."block_timestamp",
    lr."oracle_request_id",
    sym.value::STRING                                                         AS "symbol",
    rate.value::NUMBER
      / NULLIF(
            TRY_PARSE_JSON(lr."decoded_result":"calldata"):"multiplier"::NUMBER,
            0
        )                                                                     AS "adjusted_rate"
FROM   latest_requests AS lr
       , LATERAL FLATTEN(
             input => TRY_PARSE_JSON(lr."decoded_result":"calldata"):"symbols"
         )  sym
       , LATERAL FLATTEN(
             input => TRY_PARSE_JSON(lr."decoded_result":"result"):"rates"
         )  rate
WHERE  sym.index = rate.index                                                 -- align arrays
ORDER  BY lr."block_timestamp_truncated" DESC,
          lr."oracle_request_id",
          sym.index;