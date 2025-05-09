WITH all_tx AS (

    /* ------------  OUTPUTS  ------------ */
    SELECT
        FLATTENED_ADDR.value::STRING                                     AS "ADDRESS",
        TO_TIMESTAMP("block_timestamp"/1e6)                              AS "TX_TIME",
        "value"::NUMBER                                                  AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS",
         LATERAL FLATTEN( INPUT => TO_VARIANT("addresses") )             AS FLATTENED_ADDR
    WHERE TO_TIMESTAMP("block_timestamp"/1e6)
              BETWEEN '2017-10-01' AND '2017-10-31 23:59:59'

    UNION ALL

    /* ------------  INPUTS  ------------- */
    SELECT
        FLATTENED_ADDR.value::STRING                                     AS "ADDRESS",
        TO_TIMESTAMP("block_timestamp"/1e6)                              AS "TX_TIME",
        "value"::NUMBER                                                  AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS",
         LATERAL FLATTEN( INPUT => TO_VARIANT("addresses") )             AS FLATTENED_ADDR
    WHERE TO_TIMESTAMP("block_timestamp"/1e6)
              BETWEEN '2017-10-01' AND '2017-10-31 23:59:59'
),

per_address AS (
    SELECT
        "ADDRESS",
        MAX("TX_TIME")                       AS "LAST_TX_TIME",
        SUM("VALUE")                         AS "TOTAL_VALUE_OCT_2017"
    FROM all_tx
    GROUP BY "ADDRESS"
),

latest_date AS (
    SELECT MAX("LAST_TX_TIME") AS "MAX_LAST_TX_TIME"
    FROM   per_address
)

SELECT
    p."ADDRESS",
    p."LAST_TX_TIME",
    p."TOTAL_VALUE_OCT_2017"
FROM   per_address      p
JOIN   latest_date      d
  ON   p."LAST_TX_TIME" = d."MAX_LAST_TX_TIME"
ORDER  BY
       p."TOTAL_VALUE_OCT_2017" DESC NULLS LAST
LIMIT  1;