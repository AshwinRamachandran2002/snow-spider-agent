WITH params AS (
  SELECT
    t."event_timestamp",
    MAX(CASE WHEN f.value:"key"::STRING = 'board' THEN f.value:"value" END) AS "board_value",
    MAX(CASE WHEN f.value:"key"::STRING = 'value' THEN f.value:"value" END) AS "score_value"
  FROM
    FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t,
    LATERAL FLATTEN(input => t."event_params") f
  WHERE
    t."event_name" = 'level_complete_quickplay'
  GROUP BY
    t."event_timestamp"
)
SELECT
  params."board_value":"string_value"::STRING AS "Board_Type",
  ROUND(AVG(params."score_value":"int_value"::FLOAT), 4) AS "Average_Score"
FROM params
WHERE params."board_value" IS NOT NULL AND params."score_value" IS NOT NULL
GROUP BY params."board_value":"string_value"
ORDER BY "Average_Score" DESC NULLS LAST;