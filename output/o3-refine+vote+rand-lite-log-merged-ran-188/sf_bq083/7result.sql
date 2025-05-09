/* Daily net change (mint – burn) in USDC market value during 2023 */
WITH tx AS (
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                 AS "date",
        LEFT("input", 10)                                              AS "selector",

        /* decode amount (6 decimals) from call-data */
        CASE
            WHEN LEFT("input", 10) = '0x40c10f19' THEN                 -- mint: 3rd word
                 TRY_TO_NUMBER(SUBSTRING("input", 75, 64), 16) / 1e6
            ELSE                                                       -- burn: 1st word
                 TRY_TO_NUMBER(SUBSTRING("input", 11, 64), 16) / 1e6
        END                                                            AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND LEFT("input", 10) IN ('0x40c10f19', '0x42966c68')            -- mint / burn
      AND "block_timestamp" BETWEEN 1672531200000000                   -- 2023-01-01 00:00 UTC
                                 AND     1704067199000000              -- 2023-12-31 23:59 UTC
)

SELECT
    TO_CHAR("date", 'YYYY-MM-DD')                                      AS "date",
    TO_CHAR(
        SUM(CASE WHEN "selector" = '0x40c10f19' 
                 THEN  "amount"         /* mint  → + */
                 ELSE - "amount" END),  /* burn → – */
        'FM999,999,999,990D00'
    )                                                                  AS "Δ_Total_Market_Value_USD"
FROM tx
WHERE "amount" IS NOT NULL
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;