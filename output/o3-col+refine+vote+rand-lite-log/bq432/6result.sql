-- Food-events (Jan 1 – 31 2015) with cleansed text fields and length metrics
WITH cleaned AS (
  SELECT
    report_number,
    date_created,
    date_started,

    -- 1. split comma-delimited text into arrays
    SPLIT(reactions, ',')          AS reactions_arr,
    SPLIT(outcomes , ',')          AS outcomes_arr,

    -- 2. products_brand_name: protect numeric “digit, digit”, swap other commas, then restore
    REGEXP_REPLACE(                          -- step-3: restore numeric commas
      REGEXP_REPLACE(                        -- step-2: change “, ” → “ -- ”
        REGEXP_REPLACE(                      -- step-1: protect “digit, digit”
          products_brand_name,
          r'(\d+),\s*(\d+)', r'\1##\2'),
        ', ', ' -- '),
      '##', ', ') AS clean_products_brand_name,

    -- 3. simple “, ” → “ -- ” replacement
    REPLACE(products_industry_code , ', ', ' -- ') AS clean_products_industry_code,
    REPLACE(products_role          , ', ', ' -- ') AS clean_products_role,
    REPLACE(products_industry_name , ', ', ' -- ') AS clean_products_industry_name
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  report_number,
  date_created,
  date_started,
  reactions_arr,
  outcomes_arr,
  clean_products_brand_name,
  clean_products_industry_code,
  clean_products_role,
  clean_products_industry_name,

  -- length metrics
  ARRAY_LENGTH(SPLIT(clean_products_brand_name      , ' -- ')) AS brand_name_length,
  ARRAY_LENGTH(SPLIT(clean_products_industry_code   , ' -- ')) AS industry_code_length
FROM cleaned;