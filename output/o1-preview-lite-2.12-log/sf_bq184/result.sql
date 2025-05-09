WITH date_list AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2017-01-01') AS "Date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
),
external_creations AS (
    SELECT
      DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "Date",
      COUNT(*) AS "External_Creations"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE
      "trace_type" = 'create' 
      AND "trace_address" IS NULL
      AND DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY "Date"
),
internal_creations AS (
    SELECT
      DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "Date",
      COUNT(*) AS "Internal_Creations"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE
      "trace_type" = 'create' 
      AND "trace_address" IS NOT NULL
      AND DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY "Date"
)
SELECT
    "Date",
    SUM("External_Creations") OVER (
        ORDER BY "Date" 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Cumulative_External_Creations",
    SUM("Internal_Creations") OVER (
        ORDER BY "Date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Cumulative_Internal_Creations"
FROM (
    SELECT
        dl."Date",
        COALESCE(ec."External_Creations", 0) AS "External_Creations",
        COALESCE(ic."Internal_Creations", 0) AS "Internal_Creations"
    FROM date_list dl
    LEFT JOIN external_creations ec ON dl."Date" = ec."Date"
    LEFT JOIN internal_creations ic ON dl."Date" = ic."Date"
    WHERE dl."Date" BETWEEN '2017-01-01' AND '2021-12-31'
)
ORDER BY "Date";