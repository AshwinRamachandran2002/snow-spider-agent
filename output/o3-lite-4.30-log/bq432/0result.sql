WITH jan_2015_events AS (
  SELECT
    -- unique identifier
    report_number AS event_id,
    date_created,
    date_started,

    -- split lists into arrays
    SPLIT(reactions, ',')  AS reactions,
    SPLIT(outcomes , ',')  AS outcomes,

    -- protect “digit , digit”, change other “, ” to “ -- ”
    REGEXP_REPLACE(
      REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1##\2'),
      r',\s', ' -- '
    ) AS brand_tmp,

    -- replace “, ” with “ -- ” in the other fields
    REGEXP_REPLACE(products_industry_code , r',\s', ' -- ') AS products_industry_code,
    REGEXP_REPLACE(products_role         , r',\s', ' -- ') AS products_role,
    REGEXP_REPLACE(products_industry_name, r',\s', ' -- ') AS products_industry_name
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  event_id,
  date_created,
  date_started,
  reactions,
  outcomes,
  -- restore numeric commas
  REGEXP_REPLACE(brand_tmp, '##', ', ')                           AS products_brand_name,
  products_industry_code,
  products_role,
  products_industry_name,
  ARRAY_LENGTH(SPLIT(products_industry_code, ' -- '))             AS industry_code_length,
  ARRAY_LENGTH(
    SPLIT(REGEXP_REPLACE(brand_tmp, '##', ', '), ' -- ')
  )                                                               AS brand_name_length
FROM jan_2015_events;