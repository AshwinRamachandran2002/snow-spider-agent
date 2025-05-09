SELECT s.VALUE::STRING AS "Symbol",
       ROUND((r.VALUE::NUMBER / t.calldata_json['multiplier']::NUMBER), 4) AS "Rate"
FROM (
  SELECT
    t.*,
    PARSE_JSON(t."decoded_result") AS dr,
    PARSE_JSON(t."request") AS req,
    PARSE_JSON(dr['calldata']) AS calldata_json,
    PARSE_JSON(dr['result']) AS result_json
  FROM "CRYPTO"."CRYPTO_BAND"."ORACLE_REQUESTS" t
  WHERE CAST(req['oracle_script_id'] AS NUMBER) = 3
  ORDER BY t."block_timestamp" DESC NULLS LAST
  LIMIT 1
) t,
LATERAL FLATTEN(input => t.calldata_json['symbols']) s,
LATERAL FLATTEN(input => t.result_json['rates']) r
WHERE s.INDEX = r.INDEX
ORDER BY s.INDEX ASC
LIMIT 10;