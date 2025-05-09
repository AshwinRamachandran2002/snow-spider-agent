WITH ipc_counts AS (
  SELECT 
    t1."publication_number",
    SUBSTR(fipc.value::VARIANT:"code"::STRING, 1, 4) AS "ipc4_code",
    COUNT(*) AS "occurrences_per_ipc"
  FROM PATENTS.PATENTS.PUBLICATIONS t1
  CROSS JOIN LATERAL FLATTEN(input => t1."citation") fc
  JOIN PATENTS.PATENTS.PUBLICATIONS cp ON fc.value::VARIANT:"publication_number"::STRING = cp."publication_number"
  CROSS JOIN LATERAL FLATTEN(input => cp."ipc") fipc
  WHERE t1."country_code" = 'US'
    AND t1."kind_code" = 'B2'
    AND t1."grant_date" BETWEEN 20150101 AND 20181231
  GROUP BY t1."publication_number", "ipc4_code"
),
total_occurrences AS (
  SELECT 
    "publication_number",
    SUM("occurrences_per_ipc") AS "total_occurrences"
  FROM ipc_counts
  GROUP BY "publication_number"
),
sum_occurrences_squared AS (
  SELECT
    "publication_number",
    SUM(POWER("occurrences_per_ipc", 2)) AS "sum_occurrences_per_ipc_squared"
  FROM ipc_counts
  GROUP BY "publication_number"
),
originality_scores AS (
  SELECT
    t."publication_number",
    1 - (s."sum_occurrences_per_ipc_squared" / POWER(t."total_occurrences", 2)) AS "originality_score"
  FROM total_occurrences t
  JOIN sum_occurrences_squared s ON t."publication_number" = s."publication_number"
  WHERE t."total_occurrences" > 0
)

SELECT "publication_number" AS "Publication_Number", ROUND("originality_score", 4) AS "Originality_Score"
FROM originality_scores
ORDER BY "originality_score" DESC NULLS LAST, "publication_number" ASC
LIMIT 1;