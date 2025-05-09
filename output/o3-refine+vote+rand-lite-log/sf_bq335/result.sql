WITH tx AS (
    /* collect every (address , transaction‑date , value) from both Bitcoin inputs and outputs */
    SELECT
        addr.value::string                              AS "ADDRESS",
        TO_DATE(TO_TIMESTAMP("block_timestamp"/1e6))    AS "TX_DATE",
        TO_NUMBER("value")                              AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"  o,
         LATERAL FLATTEN(input => o."addresses") addr

    UNION ALL

    SELECT
        addr.value::string                              AS "ADDRESS",
        TO_DATE(TO_TIMESTAMP("block_timestamp"/1e6))    AS "TX_DATE",
        TO_NUMBER("value")                              AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"   i,
         LATERAL FLATTEN(input => i."addresses") addr
),
/* keep only transactions that happened in October 2017 */
oct_tx AS (
    SELECT *
    FROM   tx
    WHERE  "TX_DATE" BETWEEN '2017-10-01' AND '2017-10-31'
),
/* for each address: its last transaction‑date in Oct‑2017 and total value in the month */
addr_stats AS (
    SELECT
        "ADDRESS",
        MAX("TX_DATE")            AS "LAST_TX_DATE",
        SUM("VALUE")              AS "TOTAL_VALUE"
    FROM   oct_tx
    GROUP  BY "ADDRESS"
),
/* latest date among all addresses */
latest_date AS (
    SELECT MAX("LAST_TX_DATE") AS "MAX_LAST_DATE"
    FROM   addr_stats
),
/* addresses whose final transaction occurred on that latest date */
latest_addrs AS (
    SELECT s.*
    FROM   addr_stats s
    JOIN   latest_date d
      ON   s."LAST_TX_DATE" = d."MAX_LAST_DATE"
)
/* choose the one with the highest total value (ties broken alphabetically) */
SELECT "ADDRESS"
FROM   latest_addrs
ORDER  BY "TOTAL_VALUE" DESC NULLS LAST,
          "ADDRESS"
LIMIT  1;