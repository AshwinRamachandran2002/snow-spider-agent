-- Task: Pull the blockchain timestamp, block number, and transaction hash for mint events from Ethereum logs for the address '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'. Include only events identified by the topic '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde', order them by block timestamp from the oldest to the newest, and limit the results to 100 entries.

SELECT
    logs."block_timestamp",
    logs."block_number",
    logs."transaction_hash"
FROM CRYPTO.CRYPTO_ETHEREUM.LOGS AS logs
WHERE logs."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
  AND logs."topics"[0] = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
ORDER BY logs."block_timestamp"
LIMIT 100;