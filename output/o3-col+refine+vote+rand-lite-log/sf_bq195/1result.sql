/* Top 10 Ethereum addresses by net balance (incoming – outgoing – gas fees)
   using only successful transactions whose root-level trace has call_type
   NULL or 'call', and that occurred before 2021-09-01 (timestamp < 1630454400000000) */

WITH
/* -------------------------------------------------------------------- */
/* all successful transactions before the cut-off                       */
tx_filtered AS (
    SELECT
        t."hash",
        t."from_address",
        t."to_address",
        t."value",
        t."receipt_gas_used",
        t."gas_price"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS AS t
    WHERE t."receipt_status" = 1
      AND t."block_timestamp" < 1630454400000000
),
/* -------------------------------------------------------------------- */
/* root-level traces whose call_type is NULL or 'call'                  */
root_calls AS (
    SELECT DISTINCT "transaction_hash"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE ( "trace_address" IS NULL OR "trace_address" = '' )
      AND ( "call_type" IS NULL OR LOWER("call_type") = 'call' )
),
/* -------------------------------------------------------------------- */
/* keep only transactions that match the root-trace criterion           */
qualified_tx AS (
    SELECT f.*
    FROM tx_filtered AS f
    JOIN root_calls  AS r
      ON r."transaction_hash" = f."hash"
),
/* -------------------------------------------------------------------- */
/* outgoing: value sent + gas fee                                       */
outgoing AS (
    SELECT
        "from_address"                           AS "address",
        SUM( "value" + "receipt_gas_used" * "gas_price" ) AS "out_wei"
    FROM qualified_tx
    GROUP BY "from_address"
),
/* incoming: value received                                             */
incoming AS (
    SELECT
        "to_address"         AS "address",
        SUM( "value" )       AS "in_wei"
    FROM qualified_tx
    GROUP BY "to_address"
),
/* -------------------------------------------------------------------- */
/* combine to get net balance                                           */
net AS (
    SELECT
        COALESCE(i."address", o."address")            AS "address",
        COALESCE(i."in_wei", 0) - COALESCE(o."out_wei", 0) AS "net_wei"
    FROM incoming i
    FULL JOIN outgoing o USING ("address")
)
/* -------------------------------------------------------------------- */
SELECT
    "address",
    ROUND( "net_wei" / POW(10, 18), 4 ) AS "net_balance_eth"
FROM net
ORDER BY "net_balance_eth" DESC NULLS LAST
LIMIT 10;