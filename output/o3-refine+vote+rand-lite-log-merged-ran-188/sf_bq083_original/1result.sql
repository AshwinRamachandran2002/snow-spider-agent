WITH usdc_tx AS (
    SELECT
        /* calendar date (UTC) */
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))                AS "day",

        /* +1 for mint, -1 for burn */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN  1      /* mint  */
            WHEN "input" ILIKE '0x42966c68%' THEN -1      /* burn  */
        END                                                                AS sign,

        /* 64‑hex‑char amount slice                                        */
        SUBSTR(
            "input",
            CASE
                WHEN "input" ILIKE '0x40c10f19%' THEN 75   /* mint  */
                ELSE 11                                    /* burn  */
            END,
            64
        )                                                                AS amt_hex
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'            -- USDC
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')            -- mint/burn
      AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))
            BETWEEN '2023-01-01' AND '2023-12-31'
      AND "input" IS NOT NULL
)

SELECT
    "day",
    TO_CHAR(
        SUM(
            sign
            * COALESCE(
                  TRY_TO_NUMBER(                                     -- safe hex → dec
                      UPPER( NULLIF(LTRIM(amt_hex, '0'), '') ),      -- remove 0‑padding
                      16
                  ),
                  0
              ) / 1e6                                               -- USDC 6‑decimals
        ),
        'FM$999,999,999,999,990.00'
    ) AS "Δ Total Market Value"
FROM usdc_tx
GROUP BY "day"
ORDER BY "day" DESC NULLS LAST;