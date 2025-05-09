WITH date_range AS (
  SELECT DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, TO_DATE('2017-01-01')) AS "Date"
  FROM (
    SELECT 1 FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES" LIMIT 1826
  )
),
daily_counts AS (
  SELECT
    DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "Date",
    COUNT(CASE WHEN "trace_address" IS NULL THEN 1 END) AS "External_Creations",
    COUNT(CASE WHEN "trace_address" IS NOT NULL THEN 1 END) AS "Internal_Creations"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
  WHERE "trace_type" = 'create'
    AND DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) BETWEEN '2017-01-01' AND '2021-12-31'
  GROUP BY "Date"
),
cumulative_counts AS (
  SELECT
    dr."Date",
    COALESCE(dc."External_Creations", 0) AS "External_Creations",
    COALESCE(dc."Internal_Creations", 0) AS "Internal_Creations"
  FROM date_range dr
  LEFT JOIN daily_counts dc ON dr."Date" = dc."Date"
),
final_counts AS (
  SELECT
    "Date",
    ROUND(SUM("External_Creations") OVER (ORDER BY "Date"), 4) AS "Cumulative_External_Creations",
    ROUND(SUM("Internal_Creations") OVER (ORDER BY "Date"), 4) AS "Cumulative_Internal_Creations"
  FROM cumulative_counts
)
SELECT
  "Date",
  "Cumulative_External_Creations",
  "Cumulative_Internal_Creations"
FROM final_counts
ORDER BY "Date";