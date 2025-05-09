WITH date_span AS (       -- every calendar day in the required range
    SELECT
        DATEADD(day, seq4(), TO_DATE('2018-08-30')) AS "event_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))            -- 32 days: 30-Aug-18 … 30-Sep-18
),

daily_new AS (            -- new contracts per day and creator type
    SELECT
        TO_DATE(DATE_TRUNC('day',
               TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)))      AS "event_date",
        SUM(CASE WHEN "trace_address" IS NULL      THEN 1 ELSE 0 END) AS "external_new",
        SUM(CASE WHEN "trace_address" IS NOT NULL  THEN 1 ELSE 0 END) AS "contract_new"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(DATE_TRUNC('day',
             TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)))
          BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY "event_date"
),

all_days AS (             -- ensure every date is present, fill 0 where missing
    SELECT
        d."event_date",
        COALESCE(n."external_new", 0)  AS "external_new",
        COALESCE(n."contract_new", 0)  AS "contract_new"
    FROM date_span d
    LEFT JOIN daily_new n USING ("event_date")
)

SELECT
    "event_date",
    SUM("external_new") OVER(ORDER BY "event_date")  AS "cumulative_external_user_contracts",
    SUM("contract_new") OVER(ORDER BY "event_date")  AS "cumulative_contract_created_contracts"
FROM all_days
ORDER BY "event_date";