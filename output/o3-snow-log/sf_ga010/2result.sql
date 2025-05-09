/*---------------------------------------------------------
   1.  UNION ALL December-2020 GA4 export tables
   2.  Extract ga_session_id , source , medium from EVENT_PARAMS
   3.  One row per session (user_pseudo_id + ga_session_id)
   4.  Assign Default Channel Group (basic rules, case handled with LOWER())
   5.  Count & rank channels – return the 4-th most common
---------------------------------------------------------*/
WITH union_events AS (
    SELECT * FROM (
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230"  UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
    )
),

/* 2.  Extract session-level parameters */
event_params AS (
    SELECT
        e."USER_PSEUDO_ID",
        MAX( IFF( f.value:"key"::string = 'ga_session_id'
                 , f.value:"value":"int_value"::number
                 , NULL) )                    AS ga_session_id,
        LOWER( MAX( IFF( f.value:"key"::string = 'source'
                        , f.value:"value":"string_value"::string
                        , NULL) ) )            AS source,
        LOWER( MAX( IFF( f.value:"key"::string = 'medium'
                        , f.value:"value":"string_value"::string
                        , NULL) ) )            AS medium
    FROM union_events  e
        ,LATERAL FLATTEN( INPUT => e."EVENT_PARAMS" ) f
    GROUP BY
        e."USER_PSEUDO_ID",
        e."EVENT_TIMESTAMP"
),

/* 3.  One row per session */
distinct_sessions AS (
    SELECT DISTINCT
           "USER_PSEUDO_ID"     AS user_id,
           ga_session_id,
           source,
           medium
    FROM event_params
    WHERE ga_session_id IS NOT NULL
),

/* 4.  Default Channel Grouping (simplified) */
channel_sessions AS (
    SELECT
        CASE
            WHEN source = '(direct)' AND medium IN ('(none)','(not set)','')          THEN 'Direct'
            WHEN medium = 'affiliate'                                                THEN 'Affiliates'
            WHEN medium IN ('display','banner','expandable','interstitial','cpm')    THEN 'Display'
            WHEN source RLIKE 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex'
                 AND medium RLIKE 'cp|cpc|ppc|paid'                                  THEN 'Paid Search'
            WHEN medium = 'email'  OR source = 'email'                               THEN 'Email'
            WHEN medium = 'referral'                                                 THEN 'Referral'
            WHEN source RLIKE 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp'
                 AND medium RLIKE 'cp|ppc|paid|retargeting'                          THEN 'Paid Social'
            WHEN source RLIKE 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex'
                 OR   medium = 'organic'                                             THEN 'Organic Search'
            WHEN source RLIKE 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp'
                 OR   medium IN ('social','social-network','social-media','sm',
                                 'social network','social media')                    THEN 'Organic Social'
            ELSE 'Unassigned'
        END                                             AS channel_group,
        COUNT(*)                                        AS sessions
    FROM distinct_sessions
    GROUP BY channel_group
),

/* 5.  Rank & return 4-th */
ranked AS (
    SELECT
        channel_group,
        sessions,
        ROW_NUMBER() OVER (ORDER BY sessions DESC NULLS LAST) AS rn
    FROM channel_sessions
)

SELECT
    channel_group   AS fourth_highest_channel,
    sessions        AS session_count
FROM ranked
WHERE rn = 4;