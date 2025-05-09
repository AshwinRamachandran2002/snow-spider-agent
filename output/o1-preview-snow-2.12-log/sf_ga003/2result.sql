SELECT
    ed."level_name" AS "Board_Type",
    ROUND(AVG(ed."score"), 4) AS "Average_Score"
FROM
    (
        SELECT
            t."user_pseudo_id",
            t."event_timestamp",
            -- Extract the score from event parameters
            MAX(
                CASE WHEN (ep.value:"key")::STRING = 'value' THEN 
                    COALESCE(
                        (ep.value:"value"):"double_value"::FLOAT, 
                        (ep.value:"value"):"int_value"::FLOAT
                    )
                END
            ) AS "score",
            -- Extract the level name (board type) from event parameters
            MAX(
                CASE WHEN (ep.value:"key")::STRING = 'level_name' THEN 
                    (ep.value:"value"):"string_value"::STRING
                END
            ) AS "level_name"
        FROM
            "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915" t
        -- Flatten the event_params array to access individual parameters
        , LATERAL FLATTEN(input => t."event_params") ep
        WHERE
            t."event_name" = 'level_complete'
        GROUP BY
            t."user_pseudo_id",
            t."event_timestamp"
    ) ed
WHERE
    ed."level_name" IS NOT NULL
GROUP BY
    ed."level_name"
ORDER BY
    ed."level_name";