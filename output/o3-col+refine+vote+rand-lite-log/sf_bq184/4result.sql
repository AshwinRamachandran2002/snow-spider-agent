/* Daily cumulative number of Ethereum smart-contract creations
   (EOA-initiated vs contract-initiated) between 2017-01-01 and 2021-12-31 */

WITH calendar AS (   -- 1 row per day in the period (inclusive)
    SELECT
        DATEADD(day, SEQ4(), DATE '2017-01-01') AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))     -- 1826 days from 2017-01-01 to 2021-12-31
),

creations AS (        -- creation traces with their calendar day
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ(b."timestamp" / 1e6)) AS "day",
        CASE WHEN t."trace_address" IS NULL THEN 1 ELSE 0 END AS "eoa_new",
        CASE WHEN t."trace_address" IS NULL THEN 0 ELSE 1 END AS "contract_new"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES  t
    JOIN CRYPTO.CRYPTO_ETHEREUM.BLOCKS  b
      ON b."number" = t."block_number"
    WHERE t."trace_type" = 'create'
      AND TO_DATE(TO_TIMESTAMP_NTZ(b."timestamp" / 1e6))
          BETWEEN DATE '2017-01-01' AND DATE '2021-12-31'
),

daily_totals AS (     -- net new contracts per day
    SELECT
        "day",
        SUM("eoa_new")      AS "eoa_new",
        SUM("contract_new") AS "contract_new"
    FROM creations
    GROUP BY "day"
),

days_with_counts AS ( -- ensure every day appears
    SELECT
        c."day",
        COALESCE(d."eoa_new",      0) AS "eoa_new",
        COALESCE(d."contract_new", 0) AS "contract_new"
    FROM calendar c
    LEFT JOIN daily_totals d USING ("day")
)

SELECT
    "day",
    SUM("eoa_new")      OVER (ORDER BY "day") AS "cumulative_eoa_creations",
    SUM("contract_new") OVER (ORDER BY "day") AS "cumulative_contract_creations"
FROM days_with_counts
ORDER BY "day";