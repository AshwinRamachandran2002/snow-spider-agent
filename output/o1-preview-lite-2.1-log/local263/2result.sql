WITH
non_stack AS (
  SELECT "name", "version", MAX("test_score") AS "max_non_stack_score"
  FROM "model_score"
  WHERE "model" != 'Stack'
  GROUP BY "name", "version"
),
stack AS (
  SELECT "name", "version", MAX("test_score") AS "stack_score"
  FROM "model_score"
  WHERE "model" = 'Stack'
  GROUP BY "name", "version"
),
status_table AS (
  SELECT
    non_stack."name",
    non_stack."version",
    CASE
      WHEN non_stack."max_non_stack_score" < stack."stack_score" THEN 'strong'
      WHEN non_stack."max_non_stack_score" = stack."stack_score" THEN 'soft'
  END AS "status"
  FROM non_stack
  JOIN stack ON non_stack."name" = stack."name" AND non_stack."version" = stack."version"
  WHERE non_stack."max_non_stack_score" <= stack."stack_score"
),
status_L1 AS (
  SELECT
    status_table."status",
    mo."L1_model"
  FROM status_table
  JOIN "model" mo
    ON status_table."name" = mo."name" AND status_table."version" = mo."version"
),
counts AS (
  SELECT
    status_L1."status",
    status_L1."L1_model",
    COUNT(*) AS "count"
  FROM status_L1
  GROUP BY status_L1."status", status_L1."L1_model"
),
max_counts AS (
  SELECT
    "status",
    MAX("count") AS "max_count"
  FROM counts
  GROUP BY "status"
)
SELECT
  counts."status",
  counts."L1_model",
  counts."count"
FROM counts
JOIN max_counts
  ON counts."status" = max_counts."status" AND counts."count" = max_counts."max_count";