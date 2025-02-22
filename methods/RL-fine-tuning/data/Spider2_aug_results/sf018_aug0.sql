-- Task: Retrieve detailed metrics on push notification engagement, including counts and unique user counts of sends, bounces, opens, and influenced opens, for the one-hour window between 8:00 AM and 9:00 AM on June 1, 2023. The data should include app_group_id, campaign_id, user_id, send time, push open time, message_variation_id, platform, ad_tracking_enabled, carrier, browser, and device_model.
WITH push_send AS (
    SELECT
        id,
        app_group_id,
        user_id,
        campaign_id,
        message_variation_id,
        platform,
        ad_tracking_enabled,
        TO_TIMESTAMP(TIME) AS "TIME",
        'Send' AS "EVENT_TYPE"
    FROM
        BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW
    WHERE
        TO_TIMESTAMP(TIME) BETWEEN '2023-06-01 08:00:00' AND '2023-06-01 09:00:00'
),
push_bounce AS (
    SELECT
        id,
        app_group_id,
        user_id,
        campaign_id,
        message_variation_id,
        platform,
        ad_tracking_enabled,
        TO_TIMESTAMP(TIME) AS "TIME",
        'Bounce' AS "EVENT_TYPE"
    FROM
        BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_BOUNCE_VIEW
    WHERE
        TO_TIMESTAMP(TIME) BETWEEN '2023-06-01 08:00:00' AND '2023-06-01 09:00:00'
),
push_open AS (
    SELECT
        id,
        app_group_id,
        user_id,
        campaign_id,
        message_variation_id,
        platform,
        ad_tracking_enabled,
        TO_TIMESTAMP(TIME) AS "TIME",
        'Open' AS "EVENT_TYPE",
        carrier,
        browser,
        device_model
    FROM
        BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW
    WHERE
        TO_TIMESTAMP(TIME) BETWEEN '2023-06-01 08:00:00' AND '2023-06-01 09:00:00'
),
push_open_influence AS (
    SELECT
        id,
        app_group_id,
        user_id,
        campaign_id,
        message_variation_id,
        platform,
        TO_TIMESTAMP(TIME) AS "TIME",
        'Influenced Open' AS "EVENT_TYPE",
        carrier,
        browser,
        device_model
    FROM
        BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_INFLUENCEDOPEN_VIEW
    WHERE
        TO_TIMESTAMP(TIME) BETWEEN '2023-06-01 08:00:00' AND '2023-06-01 09:00:00'
)
SELECT
    ps.app_group_id,
    ps.campaign_id,
    ps.user_id,
    ps.time,
    po.time AS push_open_time,
    ps.message_variation_id,
    ps.platform,
    ps.ad_tracking_enabled,
    po.carrier,
    po.browser,
    po.device_model,
    COUNT(DISTINCT ps.id) AS push_notification_sends,
    COUNT(DISTINCT ps.user_id) AS unique_push_notification_sends,
    COUNT(DISTINCT pb.id) AS push_notification_bounced,
    COUNT(DISTINCT pb.user_id) AS unique_push_notification_bounced,
    COUNT(DISTINCT po.id) AS push_notification_open,
    COUNT(DISTINCT po.user_id) AS unique_push_notification_opened,
    COUNT(DISTINCT poi.id) AS push_notification_influenced_open,
    COUNT(DISTINCT poi.user_id) AS unique_push_notification_influenced_open
FROM
    push_send ps
    LEFT JOIN push_bounce pb ON
        ps.message_variation_id = pb.message_variation_id AND
        ps.user_id = pb.user_id AND
        ps.app_group_id = pb.app_group_id
    LEFT JOIN push_open po ON
        ps.message_variation_id = po.message_variation_id AND
        ps.user_id = po.user_id AND
        ps.app_group_id = po.app_group_id
    LEFT JOIN push_open_influence poi ON
        ps.message_variation_id = poi.message_variation_id AND
        ps.user_id = poi.user_id AND
        ps.app_group_id = poi.app_group_id
GROUP BY
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;