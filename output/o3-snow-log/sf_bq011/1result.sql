WITH unified_events AS (   -- all events for the 7-day window (2021-01-01 … 2021-01-07)
    SELECT 
        "EVENT_DATE",
        "USER_PSEUDO_ID",
        ep.value:"int_value"::NUMBER AS engagement_time_msec
    FROM (
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"
    ) e,
    LATERAL FLATTEN(input => e."EVENT_PARAMS") ep
    WHERE ep.value:"key"::STRING = 'engagement_time_msec'
),
engaged_7d AS (            -- users with any positive engagement in the 7-day window
    SELECT DISTINCT "USER_PSEUDO_ID"
    FROM unified_events
    WHERE engagement_time_msec > 0
),
engaged_2d AS (            -- users with positive engagement in the last 2 days (2021-01-06, 2021-01-07)
    SELECT DISTINCT "USER_PSEUDO_ID"
    FROM unified_events
    WHERE "EVENT_DATE" IN ('20210106','20210107')
      AND engagement_time_msec > 0
)
SELECT COUNT(*) AS distinct_users
FROM engaged_7d u7
WHERE NOT EXISTS (SELECT 1
                  FROM engaged_2d u2
                  WHERE u2."USER_PSEUDO_ID" = u7."USER_PSEUDO_ID");