-- distinct pseudo-users with positive engagement time
-- in the 7-day window (2021-01-01 … 2021-01-07) who had
-- NO positive engagement time in the last 2 days
-- (2021-01-06 … 2021-01-07)

WITH engagement AS (
    /* pull only the columns we need from each daily table
       and explode the event_params array so we can test
       engagement_time_msec > 0                                           */
    SELECT
        t."USER_PSEUDO_ID"                                        AS user_id,
        TO_DATE(t."EVENT_DATE",'YYYYMMDD')                        AS event_date
    FROM (
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"
        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"
    ) t,
    LATERAL FLATTEN(input => PARSE_JSON(t."EVENT_PARAMS")) ep
    WHERE ep.value:"key"::STRING = 'engagement_time_msec'
      AND ep.value:"value":"int_value"::NUMBER > 0
),
set7 AS (      -- users with positive engagement time in 7-day window
    SELECT DISTINCT user_id
    FROM engagement
    WHERE event_date BETWEEN '2021-01-01' AND '2021-01-07'
),
set2 AS (      -- users with positive engagement time in last 2 days
    SELECT DISTINCT user_id
    FROM engagement
    WHERE event_date BETWEEN '2021-01-06' AND '2021-01-07'
)

SELECT COUNT(*) AS "DISTINCT_USERS"
FROM set7
WHERE user_id NOT IN (SELECT user_id FROM set2);