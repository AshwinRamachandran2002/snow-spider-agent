WITH
    category_names AS (
        SELECT 'Accessories' AS "category" UNION ALL
        SELECT 'Apparel' UNION ALL
        SELECT 'Brands' UNION ALL
        SELECT 'Campus Collection' UNION ALL
        SELECT 'Drinkware' UNION ALL
        SELECT 'Electronics' UNION ALL
        SELECT 'Google Redesign' UNION ALL
        SELECT 'Lifestyle' UNION ALL
        SELECT 'Nest' UNION ALL
        SELECT 'New 2015 Logo' UNION ALL
        SELECT 'Notebooks Journals' UNION ALL
        SELECT 'Office' UNION ALL
        SELECT 'Shop by Brand' UNION ALL
        SELECT 'Small Goods' UNION ALL
        SELECT 'Stationery' UNION ALL
        SELECT 'Wearables'
    ),
    normalized_categories AS (
        SELECT LOWER(REPLACE("category", ' ', '')) AS "norm_category" FROM category_names
    ),
    pages AS (
        SELECT DISTINCT
            f.value:"value":"string_value"::STRING AS "page_location"
        FROM
            "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
            LATERAL FLATTEN(input => t."EVENT_PARAMS") f
        WHERE
            t."USER_PSEUDO_ID" = '1402138.5184246691'
            AND f.value:"key"::STRING = 'page_location'
    ),
    page_data AS (
        SELECT
            "page_location",
            SPLIT("page_location", '/') AS "segments",
            ARRAY_SIZE(SPLIT("page_location", '/')) AS "num_segments"
        FROM pages
    ),
    page_segments AS (
        SELECT
            "page_location",
            "num_segments",
            "segments"[4] AS "segment4_raw",
            "segments"[5] AS "segment5_raw",
            "segments"["num_segments"] AS "last_segment_raw"
        FROM page_data
    ),
    page_normalized AS (
        SELECT
            "page_location",
            "num_segments",
            "segment4_raw",
            "segment5_raw",
            "last_segment_raw",
            LOWER(REPLACE("segment4_raw", '+', '')) AS "segment4_norm",
            LOWER(REPLACE("segment5_raw", '+', '')) AS "segment5_norm",
            LOWER(REPLACE("last_segment_raw", '+', '')) AS "last_segment_norm",
            POSITION('+' IN "segment4_raw") AS "pos_plus_in_segment4",
            POSITION('+' IN "segment5_raw") AS "pos_plus_in_segment5",
            POSITION('+' IN "last_segment_raw") AS "pos_plus_in_last_segment"
        FROM page_segments
    ),
    page_classification AS (
        SELECT
            "page_location",
            CASE
                WHEN "num_segments" >= 5 AND
                     "pos_plus_in_segment4" = 0 AND
                     "pos_plus_in_segment5" = 0 AND
                     ("segment4_norm" IN (SELECT "norm_category" FROM normalized_categories) OR
                      "segment5_norm" IN (SELECT "norm_category" FROM normalized_categories))
                THEN 'PLP'
                WHEN "num_segments" >= 5 AND
                     "pos_plus_in_last_segment" > 0 AND
                     ("segment4_norm" IN (SELECT "norm_category" FROM normalized_categories) OR
                      "segment5_norm" IN (SELECT "norm_category" FROM normalized_categories))
                THEN 'PDP'
                ELSE 'Other'
            END AS "Page_Type"
        FROM page_normalized
    )
SELECT
    "page_location" AS "Page_Name",
    "Page_Type"
FROM page_classification
ORDER BY "Page_Name";