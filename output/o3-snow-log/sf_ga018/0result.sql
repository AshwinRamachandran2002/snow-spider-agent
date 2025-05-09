/*  PLP-to-PDP transition ratio – 2-Jan-2021 (page_view events only)  */
WITH kv AS (  -- flatten the event parameters
    SELECT  e."USER_PSEUDO_ID",
            e."EVENT_TIMESTAMP",
            kv.value:"key"::STRING                  AS param_key ,
            kv.value:"value":"string_value"::STRING AS str_val  ,
            kv.value:"value":"int_value"::NUMBER    AS int_val
    FROM   GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" e
           ,LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") kv
    WHERE  e."EVENT_NAME" = 'page_view'
),

/* assemble one record per page_view (URL + session id) */
page_views AS (
    SELECT  MAX(CASE WHEN param_key = 'page_location' THEN str_val END) AS page_location ,
            MAX(CASE WHEN param_key = 'ga_session_id' THEN int_val END) AS ga_session_id
    FROM    kv
    GROUP BY "USER_PSEUDO_ID", "EVENT_TIMESTAMP"
),

/* classify each page_view */
classified AS (
    SELECT  ga_session_id ,
            page_location ,
            CASE 
                /* PDP: url contains “+” and a recognised category word */
                WHEN page_location ILIKE '%+%' 
                     AND page_location ILIKE ANY ( '%Accessories%'
                                                  ,'%Apparel%'
                                                  ,'%Brands%'
                                                  ,'%Campus Collection%'
                                                  ,'%Drinkware%'
                                                  ,'%Electronics%'
                                                  ,'%Google%Redesign%'
                                                  ,'%Lifestyle%'
                                                  ,'%Nest%'
                                                  ,'%New 2015 Logo%'
                                                  ,'%Notebooks Journals%'
                                                  ,'%Office%'
                                                  ,'%Shop by Brand%'
                                                  ,'%Small Goods%'
                                                  ,'%Stationery%'
                                                  ,'%Wearables%' )      THEN 'PDP'
                /* PLP: same category check but NO “+” in url */
                WHEN page_location NOT ILIKE '%+%'
                     AND page_location ILIKE ANY ( '%Accessories%'
                                                  ,'%Apparel%'
                                                  ,'%Brands%'
                                                  ,'%Campus Collection%'
                                                  ,'%Drinkware%'
                                                  ,'%Electronics%'
                                                  ,'%Google%Redesign%'
                                                  ,'%Lifestyle%'
                                                  ,'%Nest%'
                                                  ,'%New 2015 Logo%'
                                                  ,'%Notebooks Journals%'
                                                  ,'%Office%'
                                                  ,'%Shop by Brand%'
                                                  ,'%Small Goods%'
                                                  ,'%Stationery%'
                                                  ,'%Wearables%' )      THEN 'PLP'
                ELSE 'OTHER'
            END AS page_type
    FROM page_views
),

/* sessions that include at least one PDP view */
sessions_with_pdp AS (
    SELECT  ga_session_id
    FROM    classified
    GROUP BY ga_session_id
    HAVING  MAX(CASE WHEN page_type = 'PDP' THEN 1 ELSE 0 END) = 1
),

/* count PLP views & PLP views in sessions that also have a PDP */
counts AS (
    SELECT  SUM(CASE WHEN page_type = 'PLP' THEN 1 ELSE 0 END)                                             AS total_plp_views ,
            SUM(CASE WHEN page_type = 'PLP' 
                      AND ga_session_id IN (SELECT ga_session_id FROM sessions_with_pdp)
                      THEN 1 ELSE 0 END)                                                                   AS plp_transition_views
    FROM    classified
)

SELECT  total_plp_views                          AS "TOTAL_PLP_VIEWS" ,
        plp_transition_views                     AS "PLP_VIEWS_THAT_LED_TO_PDP" ,
        ROUND( plp_transition_views * 100.0 / NULLIF(total_plp_views ,0) , 2) 
                                                 AS "PLP_TO_PDP_PERCENTAGE"
FROM    counts;