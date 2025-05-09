WITH calendar AS (   -- generate every calendar day in the range (32 days inclusive)
    SELECT DATEADD(day, SEQ4(), '2018-08-30'::DATE) AS "event_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),

daily_creations AS ( -- count new-contract traces per day by creator type
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000)) AS "event_date",
        SUM( CASE WHEN "trace_address" IS NULL OR "trace_address" = ''  THEN 1 ELSE 0 END ) AS "external_creations",
        SUM( CASE WHEN "trace_address" IS NOT NULL AND "trace_address" <> '' THEN 1 ELSE 0 END ) AS "contract_creations"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000))
          BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY 1
),

daily_with_zeros AS ( -- ensure a row for every calendar day
    SELECT
        c."event_date",
        COALESCE(d."external_creations", 0)  AS "external_creations",
        COALESCE(d."contract_creations", 0)  AS "contract_creations"
    FROM calendar c
    LEFT JOIN daily_creations d
           ON c."event_date" = d."event_date"
)

SELECT
    "event_date",
    SUM("external_creations")  OVER (ORDER BY "event_date") AS "cumulative_external_creations",
    SUM("contract_creations")  OVER (ORDER BY "event_date") AS "cumulative_contract_creations"
FROM daily_with_zeros
ORDER BY "event_date";