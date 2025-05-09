WITH calendar AS (   -- list of every day from 2017-01-01 through 2021-12-31 (1826 rows)
    SELECT
        DATEADD(day, SEQ4(), DATE '2017-01-01') AS event_date
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
),

contract_creations AS (      -- daily contract-creation counts by creator type
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))::DATE  AS event_date,
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'external'
            ELSE 'contract'
        END                                                             AS creator_type,
        COUNT(DISTINCT "to_address")                                    AS contracts_created
    FROM   CRYPTO.CRYPTO_ETHEREUM."TRACES"
    WHERE  "trace_type" = 'create'
      AND  "block_timestamp" BETWEEN 1483228800000000      -- 2017-01-01
                               AND     1640995199999999     -- 2021-12-31 23:59:59
    GROUP  BY event_date, creator_type
),

daily_counts AS (             -- align both creator types per calendar day
    SELECT
        c.event_date,
        COALESCE(e.contracts_created, 0) AS external_created,
        COALESCE(t.contracts_created, 0) AS contract_created
    FROM calendar c
    LEFT JOIN (SELECT * FROM contract_creations WHERE creator_type = 'external') e
           ON c.event_date = e.event_date
    LEFT JOIN (SELECT * FROM contract_creations WHERE creator_type = 'contract') t
           ON c.event_date = t.event_date
),

cum AS (                       -- cumulative (monotonically increasing) totals
    SELECT
        event_date,
        SUM(external_created) OVER (ORDER BY event_date)  AS cumulative_external,
        SUM(contract_created) OVER (ORDER BY event_date)  AS cumulative_contract
    FROM daily_counts
)

SELECT *
FROM   cum
ORDER  BY event_date;