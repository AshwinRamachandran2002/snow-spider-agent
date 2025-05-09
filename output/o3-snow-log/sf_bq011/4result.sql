/*  Pseudo-users that had positive engagement time
    any time from 2021-01-01 through 2021-01-07 (inclusive)
    BUT had no positive engagement time on 2021-01-06 or 2021-01-07          */

WITH positive_engagement AS (          -- every event whose engagement_time_msec > 0
    SELECT
        "USER_PSEUDO_ID" ,
        "EVENT_DATE"
    FROM (
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210101 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210102 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210103 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210104 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210105 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210106 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0

        UNION ALL
        SELECT "USER_PSEUDO_ID","EVENT_DATE"
        FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210107 ,
             LATERAL FLATTEN ( INPUT => PARSE_JSON("EVENT_PARAMS") ) ep
        WHERE ep.value:"key" = 'engagement_time_msec'
          AND ep.value:"value":"int_value"::NUMBER > 0
    )
),

users_7day AS (                       -- positive engagement anywhere in the 7-day window
    SELECT DISTINCT "USER_PSEUDO_ID"
    FROM   positive_engagement
    WHERE  "EVENT_DATE" BETWEEN '20210101' AND '20210107'
),

users_2day AS (                       -- positive engagement in the last 2 days
    SELECT DISTINCT "USER_PSEUDO_ID"
    FROM   positive_engagement
    WHERE  "EVENT_DATE" BETWEEN '20210106' AND '20210107'
)

SELECT COUNT(*) AS "DISTINCT_PSEUDO_USERS"
FROM   users_7day  u7
LEFT   JOIN users_2day u2
       ON u7."USER_PSEUDO_ID" = u2."USER_PSEUDO_ID"
WHERE  u2."USER_PSEUDO_ID" IS NULL;