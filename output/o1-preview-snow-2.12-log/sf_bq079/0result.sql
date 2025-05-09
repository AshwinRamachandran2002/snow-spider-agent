WITH
  latest_timberland_evals AS (
    SELECT
      "state_code",
      MAX("evaluation_group") AS "latest_evaluation_group"
    FROM "USFS_FIA"."USFS_FIA"."ESTIMATED_TIMBERLAND_ACRES"
    GROUP BY "state_code"
  ),
  timberland_acres AS (
    SELECT
      t."state_code",
      e."latest_evaluation_group" AS "evaluation_group",
      t."state_name",
      ROUND(SUM(t."subplot_acres"), 4) AS "Total_acres"
    FROM
      "USFS_FIA"."USFS_FIA"."ESTIMATED_TIMBERLAND_ACRES" t
      JOIN latest_timberland_evals e
        ON t."state_code" = e."state_code" AND t."evaluation_group" = e."latest_evaluation_group"
    GROUP BY
      t."state_code", e."latest_evaluation_group", t."state_name"
  ),
  top_timberland_state AS (
    SELECT * FROM timberland_acres
    ORDER BY "Total_acres" DESC NULLS LAST
    LIMIT 1
  ),
  latest_forestland_evals AS (
    SELECT
      "state_code",
      MAX("evaluation_group") AS "latest_evaluation_group"
    FROM "USFS_FIA"."USFS_FIA"."ESTIMATED_FORESTLAND_ACRES"
    GROUP BY "state_code"
  ),
  forestland_acres AS (
    SELECT
      t."state_code",
      e."latest_evaluation_group" AS "evaluation_group",
      t."state_name",
      ROUND(SUM(t."subplot_acres"), 4) AS "Total_acres"
    FROM
      "USFS_FIA"."USFS_FIA"."ESTIMATED_FORESTLAND_ACRES" t
      JOIN latest_forestland_evals e
        ON t."state_code" = e."state_code" AND t."evaluation_group" = e."latest_evaluation_group"
    GROUP BY
      t."state_code", e."latest_evaluation_group", t."state_name"
  ),
  top_forestland_state AS (
    SELECT * FROM forestland_acres
    ORDER BY "Total_acres" DESC NULLS LAST
    LIMIT 1
  )
SELECT
  'Timberland' AS "Category",
  "state_code",
  "evaluation_group",
  "state_name",
  "Total_acres"
FROM top_timberland_state
UNION ALL
SELECT
  'Forestland' AS "Category",
  "state_code",
  "evaluation_group",
  "state_name",
  "Total_acres"
FROM top_forestland_state;