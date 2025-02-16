-- Task: Retrieve the board type and score value for the first 100 'level_complete_quickplay' events on September 15, 2018.
SELECT
    t."event_timestamp",
    t."user_pseudo_id",
    MAX(CASE WHEN ep.value:"key"::STRING = 'board' THEN ep.value:"value":"string_value"::STRING END) AS board,
    MAX(CASE WHEN ep.value:"key"::STRING = 'value' THEN
        COALESCE(
            ep.value:"value":"double_value"::FLOAT,
            ep.value:"value":"int_value"::FLOAT,
            TRY_TO_DOUBLE(ep.value:"value":"string_value"::STRING)
        )
    END) AS value
FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915" t,
     LATERAL FLATTEN(input => t."event_params") ep
WHERE t."event_name" = 'level_complete_quickplay'
GROUP BY t."event_timestamp", t."user_pseudo_id"
LIMIT 100;