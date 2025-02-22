-- Task: Retrieve the "block_timestamp", "block_number", and "transaction_hash" for the first five mint and burn events from the Ethereum logs stored in the "CRYPTO"."CRYPTO_ETHEREUM"."LOGS" table. Filter the logs where the "address" is '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'. Mint events are identified by logs where the first element of "topics" ("topics"[0]) is '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'; burn events are identified by logs where "topics"[0] is '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'. Combine the mint and burn events, order them by "block_timestamp" ascending (from oldest to newest), and limit the results to the first five events.

WITH parsed_burn_logs AS (
  SELECT
    logs."block_timestamp" AS block_timestamp,
    logs."block_number" AS block_number,
    logs."transaction_hash" AS transaction_hash,
    logs."log_index" AS log_index,
    PARSE_JSON(logs."data") AS data,
    logs."topics"
  FROM CRYPTO.CRYPTO_ETHEREUM.LOGS AS logs
  WHERE logs."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
    AND logs."topics"[0] = '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'
),
parsed_mint_logs AS (
  SELECT
    logs."block_timestamp" AS block_timestamp,
    logs."block_number" AS block_number,
    logs."transaction_hash" AS transaction_hash,
    logs."log_index" AS log_index,
    PARSE_JSON(logs."data") AS data,
    logs."topics"
  FROM CRYPTO.CRYPTO_ETHEREUM.LOGS AS logs
  WHERE logs."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
    AND logs."topics"[0] = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
)

SELECT
    block_timestamp,
    block_number,
    transaction_hash
FROM parsed_mint_logs

UNION ALL

SELECT
    block_timestamp,
    block_number,
    transaction_hash
FROM parsed_burn_logs

ORDER BY block_timestamp
LIMIT 5;