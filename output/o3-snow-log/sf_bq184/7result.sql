WITH calendar AS (   -- every day in the range (2017-01-01 … 2021-12-31)
    SELECT
        DATEADD(day, SEQ4(), '2017-01-01'::DATE) AS dt
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)   -- 1 826 days inclusive
    )
),

creations AS (       -- daily contract-creation counts
    SELECT
        TO_DATE(
            DATE_TRUNC(
                'day',
                TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
            )
        )                                   AS dt,
        COUNT_IF("trace_address" IS NULL)      AS ext_creations,
        COUNT_IF("trace_address" IS NOT NULL)  AS contract_creations
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_DATE(
              DATE_TRUNC(
                  'day',
                  TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
              )
          ) BETWEEN '2017-01-01'::DATE AND '2021-12-31'::DATE
    GROUP BY dt
),

daily AS (           -- calendar + counts (fill gaps with zeros)
    SELECT
        cal.dt,
        COALESCE(cr.ext_creations, 0)        AS ext_creations,
        COALESCE(cr.contract_creations, 0)   AS contract_creations
    FROM calendar cal
    LEFT JOIN creations cr USING (dt)
),

cumulative AS (      -- running totals
    SELECT
        dt,
        SUM(ext_creations)      OVER (ORDER BY dt) AS cumulative_external,
        SUM(contract_creations) OVER (ORDER BY dt) AS cumulative_contract
    FROM daily
)

SELECT
    dt  AS "date",
    cumulative_external,
    cumulative_contract
FROM cumulative
ORDER BY dt;