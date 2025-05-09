SELECT
  report_number,
  SPLIT(IFNULL(reactions, ''), ', ') AS reactions,
  SPLIT(IFNULL(outcomes, ''), ', ') AS outcomes,
  SPLIT(REGEXP_REPLACE(IFNULL(products_brand_name, ''), r'(\\d+), (\\d+)', r'\\1 -- \\2'), ', ') AS products_brand_name,
  SPLIT(REGEXP_REPLACE(IFNULL(products_industry_code, ''), ', ', ' -- '), ',') AS products_industry_code,
  SPLIT(REGEXP_REPLACE(IFNULL(products_role, ''), ', ', ' -- '), ',') AS products_role,
  SPLIT(REGEXP_REPLACE(IFNULL(products_industry_name, ''), ', ', ' -- '), ',') AS products_industry_name,
  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,
  ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(IFNULL(products_industry_code, ''), ', ', ' -- '), ',')) AS industry_code_length,
  ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(IFNULL(products_brand_name, ''), r'(\\d+), (\\d+)', r'\\1 -- \\2'), ',')) AS brand_name_length
FROM `bigquery-public-data.fda_food.food_events`
WHERE DATE(date_created) BETWEEN '2015-01-01' AND '2015-01-31';