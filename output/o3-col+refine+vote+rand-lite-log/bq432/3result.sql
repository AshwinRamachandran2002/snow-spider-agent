/*  Food-event records created AND started in January 2015,
    cleaned and enriched per the specification.            */
WITH jan15 AS (
  SELECT
    report_number,
    reactions,
    outcomes,
    products_brand_name,
    products_industry_code,
    products_role,
    products_industry_name,
    DATE(date_created) AS date_created,
    DATE(date_started) AS date_started
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE DATE(date_created) BETWEEN '2015-01-01' AND '2015-01-31'
    AND DATE(date_started) BETWEEN '2015-01-01' AND '2015-01-31'
)
SELECT
  -- 1. split arrays ---------------------------------------------------------
  SPLIT(reactions, ',') AS reactions_arr,
  SPLIT(outcomes , ',') AS outcomes_arr,

  -- 2. brand-name special cleansing ----------------------------------------
  REGEXP_REPLACE(
    REPLACE(                                           -- primary “, ” → “ -- ”
      REGEXP_REPLACE(products_brand_name,              -- protect digit, digit
                     r'(\d),\s(\d)', r'\1##\2'),
      ', ', ' -- '),
    r'(\d)##(\d)', r'\1, \2')                         AS products_brand_name_clean,

  -- 3. other product fields -------------------------------------------------
  REPLACE(products_industry_code , ', ', ' -- ') AS products_industry_code_clean,
  REPLACE(products_role          , ', ', ' -- ') AS products_role_clean,
  REPLACE(products_industry_name , ', ', ' -- ') AS products_industry_name_clean,

  -- 4. derived list lengths -------------------------------------------------
  ARRAY_LENGTH(SPLIT(
      REPLACE(products_industry_code, ', ', ' -- '), ' -- '))
        AS industry_code_length,
  ARRAY_LENGTH(SPLIT(
      REGEXP_REPLACE(
        REPLACE(REGEXP_REPLACE(products_brand_name, r'(\d),\s(\d)', r'\1##\2'),
                ', ', ' -- '),
        r'(\d)##(\d)', r'\1, \2'), ' -- '))
        AS brand_name_length,

  -- 5. identifiers & dates --------------------------------------------------
  report_number,
  date_created,
  date_started
FROM jan15;