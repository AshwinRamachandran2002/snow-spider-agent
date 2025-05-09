WITH
-- 1.  All inputs in October-2017 ------------------------------------------------
btc_inputs AS (
    SELECT
        addr.value::STRING                         AS "ADDRESS",
        DATE_TRUNC('DAY',
                   TO_TIMESTAMP("block_timestamp"/1e6))  AS "TX_DATE",
        "value"::FLOAT                             AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS",
         LATERAL FLATTEN( INPUT => PARSE_JSON("addresses") ) addr
    WHERE DATE_TRUNC('MONTH',
                     TO_TIMESTAMP("block_timestamp"/1e6)) = '2017-10-01'
),

-- 2.  All outputs in October-2017 ---------------------------------------------
btc_outputs AS (
    SELECT
        addr.value::STRING                         AS "ADDRESS",
        DATE_TRUNC('DAY',
                   TO_TIMESTAMP("block_timestamp"/1e6))  AS "TX_DATE",
        "value"::FLOAT                             AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS",
         LATERAL FLATTEN( INPUT => PARSE_JSON("addresses") ) addr
    WHERE DATE_TRUNC('MONTH',
                     TO_TIMESTAMP("block_timestamp"/1e6)) = '2017-10-01'
),

-- 3.  Union inputs and outputs -------------------------------------------------
all_oct_tx AS (
    SELECT * FROM btc_inputs
    UNION ALL
    SELECT * FROM btc_outputs
),

-- 4.  Per-address metrics: final date & total value ----------------------------
per_address AS (
    SELECT
        "ADDRESS",
        MAX("TX_DATE")          AS "FINAL_DATE",
        SUM("VALUE")            AS "TOTAL_VALUE"
    FROM all_oct_tx
    GROUP BY "ADDRESS"
),

-- 5.  Latest final date among all addresses ------------------------------------
latest_date AS (
    SELECT MAX("FINAL_DATE") AS "LATEST_FINAL_DATE"
    FROM   per_address
),

-- 6.  Addresses whose final tx is on that latest date --------------------------
candidates AS (
    SELECT p.*
    FROM   per_address p
    JOIN   latest_date  d
      ON   p."FINAL_DATE" = d."LATEST_FINAL_DATE"
)

-- 7.  Pick address with largest October value ----------------------------------
SELECT   "ADDRESS"
FROM     candidates
ORDER BY "TOTAL_VALUE" DESC NULLS LAST
LIMIT    1;