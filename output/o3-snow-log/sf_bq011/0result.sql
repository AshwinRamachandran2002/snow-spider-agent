WITH seven_day_events AS (

    /* 7-day window : 2021-01-01 ‑- 2021-01-07 */
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210101"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210103"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210104"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210105"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"

), seven_day_positive AS (

    /* users with >0 engagement_time_msec during the 7-day window */
    SELECT DISTINCT s."USER_PSEUDO_ID"
    FROM seven_day_events s,
         LATERAL FLATTEN(input => s."EVENT_PARAMS") f
    WHERE f.value:key::string = 'engagement_time_msec'
      AND COALESCE(  f.value:value:int_value    ::NUMBER
                   , f.value:value:double_value ::NUMBER
                   , f.value:value:float_value  ::NUMBER
                   , 0 ) > 0

), two_day_events AS (

    /* 2-day window : 2021-01-06 ‑- 2021-01-07 */
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210106"

    UNION ALL
    SELECT "USER_PSEUDO_ID",
           "EVENT_PARAMS"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210107"

), two_day_positive AS (

    /* users with >0 engagement_time_msec during the 2-day window */
    SELECT DISTINCT t."USER_PSEUDO_ID"
    FROM two_day_events t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    WHERE f.value:key::string = 'engagement_time_msec'
      AND COALESCE(  f.value:value:int_value    ::NUMBER
                   , f.value:value:double_value ::NUMBER
                   , f.value:value:float_value  ::NUMBER
                   , 0 ) > 0
)

SELECT COUNT(*) AS "DISTINCT_PSEUDO_USERS"
FROM seven_day_positive s
LEFT JOIN two_day_positive t
       ON s."USER_PSEUDO_ID" = t."USER_PSEUDO_ID"
WHERE t."USER_PSEUDO_ID" IS NULL;