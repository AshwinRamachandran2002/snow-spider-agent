/*  distinct pseudo-users with positive engagement_time_msec
    in the 7-day window (2021-01-01 – 2021-01-07)
    but NOT in the 2-day window (2021-01-06 – 2021-01-07)          */

WITH all_events AS (      -- pull the needed fields from each daily table
    SELECT "USER_PSEUDO_ID",
           "EVENT_DATE",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_DATE", "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"
),

/* explode the EVENT_PARAMS array and keep only positive engagement_time_msec */
engagement AS (
    SELECT
        ae."USER_PSEUDO_ID"                           AS user_pseudo_id,
        TO_DATE(ae."EVENT_DATE", 'YYYYMMDD')          AS event_dt,
        f.value:value:int_value::NUMBER               AS engagement_time_msec
    FROM all_events   ae,
         LATERAL FLATTEN( INPUT => PARSE_JSON(ae."EVENT_PARAMS") ) f
    WHERE f.value:key::STRING = 'engagement_time_msec'
      AND f.value:value:int_value::NUMBER > 0
),

users_7day AS (   -- users with positive engagement in the 7-day window
    SELECT DISTINCT user_pseudo_id
    FROM engagement
    WHERE event_dt BETWEEN '2021-01-01' AND '2021-01-07'
),

users_2day AS (   -- users with positive engagement in the last 2 days
    SELECT DISTINCT user_pseudo_id
    FROM engagement
    WHERE event_dt BETWEEN '2021-01-06' AND '2021-01-07'
)

SELECT COUNT(*) AS distinct_users
FROM   users_7day
WHERE  user_pseudo_id NOT IN (SELECT user_pseudo_id FROM users_2day);