-- Task: List all push notification sends within the specified one-hour window on June 1, 2023.

SELECT
    id,
    app_group_id,
    user_id,
    campaign_id,
    message_variation_id,
    platform,
    ad_tracking_enabled,
    TO_TIMESTAMP(TIME) AS TIME
FROM
    BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW
WHERE
    TO_TIMESTAMP(TIME) BETWEEN '2023-06-01 08:00:00' AND '2023-06-01 09:00:00'
LIMIT 100;