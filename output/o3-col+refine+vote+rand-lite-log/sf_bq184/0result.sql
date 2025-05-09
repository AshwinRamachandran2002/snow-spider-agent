/* ------------------------------------------------------------
   Daily cumulative smart-contract creations on Ethereum
   (2017-01-01 – 2021-12-31)
---------------------------------------------------------------- */
WITH date_span AS (             -- calendar of every day in range
    SELECT
        DATEADD(day, SEQ4(), TO_DATE('2017-01-01')) AS "event_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))         -- 2017-01-01 … 2021-12-31
),

daily_counts AS (               -- daily counts by creation category
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))            AS "event_date",
        CASE
            WHEN "trace_address" IS NULL OR TRIM("trace_address") = ''
                 THEN 'external'                                       -- EOA-initiated
            ELSE 'internal'                                            -- contract-initiated
        END                                                            AS "category",
        COUNT(*)                                                       AS "cnt"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type" = 'create'
      AND  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
              BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP  BY 1, 2
),

merged AS (                     -- align counts with calendar, fill zeros
    SELECT
        d."event_date",
        COALESCE(SUM(CASE WHEN c."category" = 'external' THEN c."cnt" END), 0)
            AS "external_daily",
        COALESCE(SUM(CASE WHEN c."category" = 'internal' THEN c."cnt" END), 0)
            AS "internal_daily"
    FROM       date_span    d
    LEFT JOIN  daily_counts c
           ON  d."event_date" = c."event_date"
    GROUP BY   d."event_date"
)

SELECT
    "event_date",
    SUM("external_daily") OVER (ORDER BY "event_date")
        AS "cumulative_external_creations",
    SUM("internal_daily") OVER (ORDER BY "event_date")
        AS "cumulative_internal_creations"
FROM   merged
ORDER BY "event_date";