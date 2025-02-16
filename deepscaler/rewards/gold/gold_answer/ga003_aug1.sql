-- Task: Retrieve the parameters 'value' and 'board' for each 'level_complete_quickplay' event on September 15, 2018.
SELECT 
    user_pseudo_id, 
    event_timestamp, 
    param
FROM 
    `firebase-public-project.analytics_153293282.events_20180915`,
    UNNEST(event_params) AS param
WHERE 
    event_name = "level_complete_quickplay"
    AND (param.key = "value" OR param.key = "board")