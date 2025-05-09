WITH date_range AS (           -- all days in the requested interval
    SELECT
        DATEADD(day, seq4(), DATE '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))          -- 32 days: 30-Aug-2018 … 30-Sep-2018
),

daily_creations AS (           -- contract-creation traces split by origin
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp"/1000000) AS DATE)              AS "date",
        CASE WHEN "trace_address" IS NULL THEN 1 ELSE 0 END                   AS "eoa_new",
        CASE WHEN "trace_address" IS NULL THEN 0 ELSE 1 END                   AS "contract_new"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  CAST(TO_TIMESTAMP_NTZ("block_timestamp"/1000000) AS DATE)
                 BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
),

daily_totals AS (              -- aggregate per day
    SELECT
        "date",
        SUM("eoa_new")      AS "eoa_new",
        SUM("contract_new") AS "contract_new"
    FROM   daily_creations
    GROUP  BY "date"
)

SELECT
    d."date",
    SUM(NVL(t."eoa_new",0))      OVER (ORDER BY d."date") AS "cumulative_eoa_creations",
    SUM(NVL(t."contract_new",0)) OVER (ORDER BY d."date") AS "cumulative_contract_creations"
FROM      date_range d
LEFT JOIN daily_totals t
       ON d."date" = t."date"
ORDER BY  d."date";