WITH FirstHop AS (
    SELECT "to_addr" AS "intermediary_address", "id" AS "first_tx_id"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "sender" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'
),
IntermediaryTxCounts AS (
    SELECT "sender" AS "intermediary_address", COUNT(*) AS "outgoing_tx_count"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    GROUP BY "sender"
    HAVING COUNT(*) <= 50
),
ValidIntermediaries AS (
    SELECT f."intermediary_address", f."first_tx_id"
    FROM FirstHop f
    INNER JOIN IntermediaryTxCounts i ON f."intermediary_address" = i."intermediary_address"
),
SecondHop AS (
    SELECT "sender" AS "intermediary_address", "id" AS "second_tx_id"
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "to_addr" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
)
SELECT CONCAT(
    'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
    ' --(tx ', LEFT(f."first_tx_id",5), '..)--> ',
    f."intermediary_address",
    ' --(tx ', LEFT(s."second_tx_id",5), '..)--> ',
    'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
) AS "path"
FROM ValidIntermediaries f
INNER JOIN SecondHop s ON f."intermediary_address" = s."intermediary_address";