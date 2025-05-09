-- six addresses with the biggest absolute gap between their net
-- balances of the two requested ERC-20 tokens
WITH signed_transfers AS (
    /*  incoming transfers                                                   */
    SELECT
        "to_address"        AS "address",
        "token_address",
        TRY_TO_DECIMAL("value")                        AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN
          ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
           '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
      AND "to_address" <> '0x0000000000000000000000000000000000000000'

    UNION ALL
    /*  outgoing transfers – store as negative amount                        */
    SELECT
        "from_address"      AS "address",
        "token_address",
        -TRY_TO_DECIMAL("value")                       AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN
          ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
           '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
),
balances AS (
    /*  aggregate to get net balance per address & token                     */
    SELECT
        "address",
        "token_address",
        SUM("amount_signed") AS "balance"
    FROM signed_transfers
    GROUP BY "address", "token_address"
),
pivoted AS (
    /*  pivot the two token balances into separate columns                   */
    SELECT
        "address",
        /* “previous” token balance (first contract address)                 */
        COALESCE(
            MAX(CASE
                    WHEN "token_address" = '0x0d8775f648430679a709e98d2b0cb6250d2887ef0'
                    THEN "balance"
                 END), 0)                                            AS "prev_balance",
        /* “current” token balance (second contract address)                 */
        COALESCE(
            MAX(CASE
                    WHEN "token_address" = '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
                    THEN "balance"
                 END), 0)                                            AS "curr_balance"
    FROM balances
    GROUP BY "address"
)
SELECT
    "address",
    "prev_balance",
    "curr_balance",
    ABS("prev_balance" - "curr_balance")      AS "abs_diff"
FROM pivoted
ORDER BY "abs_diff" DESC NULLS LAST
LIMIT 6;