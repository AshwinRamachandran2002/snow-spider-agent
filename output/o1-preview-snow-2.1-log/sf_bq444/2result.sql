SELECT 
  ROUND(t."block_timestamp" / 1000000, 4) AS "block_timestamp",  -- Convert microseconds to seconds, round to 4 decimals
  t."block_number", 
  t."transaction_hash"
FROM CRYPTO.CRYPTO_ETHEREUM."LOGS" t
WHERE t."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
  AND t."topics"[0] IN (
    '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde',  -- Mint event topic
    '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'   -- Burn event topic
  )
ORDER BY t."block_timestamp" ASC
LIMIT 5;