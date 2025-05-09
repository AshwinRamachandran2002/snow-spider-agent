/*  Second-most viewed cleaned page path on shop.googlemerchandisestore.com
    for ALL December-2020 GA4 sample-ecommerce tables                                */

WITH page_views AS (

    /* ===== 01-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')                                    AS page_path
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 02-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 03-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 04-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 05-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 06-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 07-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 08-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 09-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 10-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 11-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 12-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 13-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 14-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 15-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 16-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 17-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 18-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 19-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 20-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 21-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 22-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 23-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 24-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 25-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 26-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 27-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 28-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 29-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 30-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'

    UNION ALL   /* ===== 31-Dec-2020 ===== */
    SELECT REGEXP_REPLACE(
             '/' || ARRAY_TO_STRING(
                     SPLIT(
                       REGEXP_REPLACE(f.value:"value":"string_value"::STRING,
                                      '^https?://[^/]+',''),
                       '/'),
                     '/'),
             '/{2,}','/')
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231" t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND SPLIT_PART(
            REGEXP_REPLACE(f.value:"value":"string_value"::STRING,'^https?://',''),
            '/', 1
          ) = 'shop.googlemerchandisestore.com'
),

path_counts AS (
    SELECT page_path,
           COUNT(*) AS total_views
    FROM page_views
    GROUP BY page_path
),

ranked AS (
    SELECT pc.*,
           ROW_NUMBER() OVER (ORDER BY pc.total_views DESC NULLS LAST) AS rn
    FROM path_counts pc
)

SELECT page_path        AS second_most_viewed_page,
       total_views      AS views_in_dec_2020
FROM ranked
WHERE rn = 2;