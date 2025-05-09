SELECT
  addr."address",
  ROUND((COALESCE(rcv."total_received", 0) - COALESCE(snt."total_sent", 0)) / POWER(10, 18), 4) AS "balance"
FROM (
  SELECT DISTINCT tt."from_address" AS "address"
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
  WHERE tt."token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
  
  UNION
  
  SELECT DISTINCT tt."to_address" AS "address"
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
  WHERE tt."token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
) addr
LEFT JOIN (
  SELECT tt."to_address" AS "address",
    SUM(TO_NUMBER(tt."value")) AS "total_received"
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
  WHERE tt."token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
  GROUP BY tt."to_address"
) rcv
ON addr."address" = rcv."address"
LEFT JOIN (
  SELECT tt."from_address" AS "address",
    SUM(TO_NUMBER(tt."value")) AS "total_sent"
  FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
  WHERE tt."token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
  GROUP BY tt."from_address"
) snt
ON addr."address" = snt."address"
WHERE addr."address" != '0x0000000000000000000000000000000000000000';