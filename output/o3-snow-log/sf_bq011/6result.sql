WITH data_7d AS (          -- users with POSITIVE engagement time from 2021-01-01 through 2021-01-07
    SELECT DISTINCT "USER_PSEUDO_ID" AS user_id
    FROM (
             SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"
         ) t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
    WHERE ep.value:"key"::STRING                              = 'engagement_time_msec'
      AND ep.value:"value":"int_value"::NUMBER               > 0
),

data_2d AS (           -- users with POSITIVE engagement time from 2021-01-06 through 2021-01-07
    SELECT DISTINCT "USER_PSEUDO_ID" AS user_id
    FROM (
             SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"
             UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"
         ) t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
    WHERE ep.value:"key"::STRING                              = 'engagement_time_msec'
      AND ep.value:"value":"int_value"::NUMBER               > 0
)

SELECT COUNT(*) AS "DISTINCT_PSEUDO_USERS"
FROM   data_7d  d7
LEFT   JOIN data_2d d2
       ON d7.user_id = d2.user_id
WHERE  d2.user_id IS NULL;