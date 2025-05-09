WITH creation_traces AS (   -- all contract‑creation traces that land a new contract address
    SELECT
        "to_address"                      AS to_addr,
        "block_timestamp"                AS ts,
        NULLIF("trace_address",'')       AS trace_addr
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE LOWER("trace_type") = 'create'

    UNION ALL

    SELECT
        "to_address"                      AS to_addr,
        "block_timestamp"                AS ts,
        NULLIF("trace_address",'')       AS trace_addr
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE LOWER("trace_type") = 'create'
),

first_creation AS (           -- earliest creation for each contract
    SELECT  to_addr,
            ts,
            trace_addr
    FROM   (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY to_addr ORDER BY ts) AS rn
        FROM    creation_traces
        WHERE   to_addr IS NOT NULL
    )
    WHERE rn = 1
),

daily_new AS (                 -- classify each new contract by creator type
    SELECT
        DATE(TO_TIMESTAMP_NTZ(ts/1e6))                       AS event_date,
        CASE WHEN trace_addr IS NULL THEN 1 ELSE 0 END       AS external_new,
        CASE WHEN trace_addr IS NOT NULL THEN 1 ELSE 0 END   AS contract_new
    FROM first_creation
),

daily_agg AS (                 -- sums per calendar day
    SELECT
        event_date,
        SUM(external_new)  AS external_new,
        SUM(contract_new)  AS contract_new
    FROM daily_new
    GROUP BY event_date
),

dates AS (                     -- every day 2017‑01‑01 .. 2021‑12‑31  (inclusive = 1 826 rows)
    SELECT DATEADD(day, SEQ4(), '2017-01-01') AS event_date
    FROM   TABLE(GENERATOR(ROWCOUNT => 1826))
),

combined AS (                  -- fill missing days with zeros
    SELECT
        d.event_date,
        COALESCE(a.external_new ,0) AS external_new,
        COALESCE(a.contract_new ,0) AS contract_new
    FROM   dates d
    LEFT   JOIN daily_agg a USING (event_date)
),

result AS (                    -- running cumulative totals
    SELECT
        event_date,
        SUM(external_new) OVER (ORDER BY event_date
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          AS cumulative_external_creations,
        SUM(contract_new)  OVER (ORDER BY event_date
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          AS cumulative_contract_creations
    FROM combined
)

SELECT *
FROM   result
ORDER  BY event_date;