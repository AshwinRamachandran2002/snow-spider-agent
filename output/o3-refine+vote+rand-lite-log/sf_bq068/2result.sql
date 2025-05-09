/*--------------------------------------------------------------------
  Final balances for every address are built from
  • OUTPUTS  → credits  (+ value)
  • INPUTS   → debits   (− value)
  The query restricts to Bitcoin‑Cash blocks whose timestamps are
  between 1‑Mar‑2014 (inclusive) and 1‑Apr‑2014 (exclusive),
  then, for every address type, returns the maximum and minimum
  of those final balances.
--------------------------------------------------------------------*/
WITH
-- credits -----------------------------------------------------------
outputs AS (
    SELECT
        /* first (and usually only) address in the JSON array */
        PARSE_JSON("addresses")[0]::string       AS address ,
        "type"                                   AS address_type ,
        "value"::decimal                         AS amt          -- +ve
    FROM   CRYPTO.CRYPTO_BITCOIN_CASH."OUTPUTS"
    WHERE  "block_timestamp" >= 1393632000000000   -- 2014‑03‑01
      AND  "block_timestamp" <  1396310400000000   -- 2014‑04‑01
),
-- debits ------------------------------------------------------------
inputs  AS (
    SELECT
        PARSE_JSON("addresses")[0]::string       AS address ,
        "type"                                   AS address_type ,
        - "value"::decimal                       AS amt          -- −ve
    FROM   CRYPTO.CRYPTO_BITCOIN_CASH."INPUTS"
    WHERE  "block_timestamp" >= 1393632000000000
      AND  "block_timestamp" <  1396310400000000
),
-- union of all legs -------------------------------------------------
legs AS (
    SELECT * FROM outputs
    UNION ALL
    SELECT * FROM inputs
),
-- final balance per address -----------------------------------------
balances AS (
    SELECT
        address_type ,
        address ,
        SUM(amt) AS balance
    FROM   legs
    GROUP  BY address_type , address
)
-- max / min balance per address type --------------------------------
SELECT
    address_type ,
    MAX(balance) AS max_balance ,
    MIN(balance) AS min_balance
FROM   balances
GROUP  BY address_type
ORDER  BY address_type;