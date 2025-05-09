WITH all_events_7day AS (   -- 2021-01-01 00:00:00  →  2021-01-07 23:59:59
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210101
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210102
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210103
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210104
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210105
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210106
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210107
),
engagement_7day AS (        -- users with positive engagement in the 7-day window
    SELECT DISTINCT ae."USER_PSEUDO_ID"
      FROM all_events_7day  ae,
           LATERAL FLATTEN ( INPUT => ae."EVENT_PARAMS" ) ep
     WHERE ep.value:"key"::string = 'engagement_time_msec'
       AND COALESCE(
             ep.value:"value":"int_value" :: NUMBER,
             ep.value:"value":"double_value" :: FLOAT,
             0
           ) > 0
),
all_events_2day AS (        -- 2021-01-06 00:00:00  →  2021-01-07 23:59:59
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210106
    UNION ALL
    SELECT "USER_PSEUDO_ID", "EVENT_PARAMS"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210107
),
engagement_2day AS (        -- users with positive engagement in the last 2 days
    SELECT DISTINCT ae."USER_PSEUDO_ID"
      FROM all_events_2day  ae,
           LATERAL FLATTEN ( INPUT => ae."EVENT_PARAMS" ) ep
     WHERE ep.value:"key"::string = 'engagement_time_msec'
       AND COALESCE(
             ep.value:"value":"int_value" :: NUMBER,
             ep.value:"value":"double_value" :: FLOAT,
             0
           ) > 0
)
SELECT COUNT(*) AS "DISTINCT_USERS"
  FROM engagement_7day
 WHERE "USER_PSEUDO_ID" NOT IN (SELECT "USER_PSEUDO_ID" FROM engagement_2day);