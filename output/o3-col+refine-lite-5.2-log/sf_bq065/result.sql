SELECT
    r."block_timestamp",
    r."oracle_request_id",
    sym.value::STRING                                                         AS "symbol",
    rat.value::FLOAT
      / COALESCE(
          TRY_TO_NUMBER(
              (PARSE_JSON(r."decoded_result":"calldata"::STRING):"multiplier")::STRING
          ),
          1
        )                                                                     AS "adjusted_rate"
FROM (
        /* 10 most‑recent oracle requests with oracle_script_id = 3 */
        SELECT *
        FROM CRYPTO.CRYPTO_BAND.ORACLE_REQUESTS
        WHERE COALESCE(
                "oracle_script":"id"::INT,
                PARSE_JSON("request"):"oracle_script_id"::INT
              ) = 3
        ORDER BY "block_height" DESC
        LIMIT 10
     ) r
     /* explode symbols and rates arrays, matching by position */
     , LATERAL FLATTEN(
         input => PARSE_JSON(r."decoded_result":"calldata"::STRING):"symbols"
       ) sym
     , LATERAL FLATTEN(
         input => PARSE_JSON(r."decoded_result":"result"  ::STRING):"rates"
       ) rat
WHERE sym.index = rat.index
ORDER BY r."block_timestamp" DESC NULLS LAST,
         r."oracle_request_id",
         sym.index;