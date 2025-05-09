WITH cleaned AS (
  SELECT
    report_number,
    -- 1) split comma-separated strings into arrays
    SPLIT(reactions, ',')  AS reactions_array,
    SPLIT(outcomes , ',')  AS outcomes_array,

    -- 2) products_brand_name: preserve digit–comma–digit patterns,
    --    replace all other “, ” with “ -- ”
    REGEXP_REPLACE(
      REGEXP_REPLACE(products_brand_name, ', ', ' -- '),
      r'([0-9]) -- ([0-9])', r'\1, \2'
    ) AS products_brand_name_clean,

    -- 3) replace “, ” with “ -- ” in the other product fields
    REGEXP_REPLACE(products_industry_code , ', ', ' -- ') AS products_industry_code_clean,
    REGEXP_REPLACE(products_role          , ', ', ' -- ') AS products_role_clean,
    REGEXP_REPLACE(products_industry_name , ', ', ' -- ') AS products_industry_name_clean,

    date_created,
    date_started
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  report_number,
  reactions_array,
  outcomes_array,
  products_brand_name_clean,
  ARRAY_LENGTH(SPLIT(products_brand_name_clean, ' -- ')) AS brand_name_length,
  products_industry_code_clean,
  ARRAY_LENGTH(SPLIT(products_industry_code_clean, ' -- ')) AS industry_code_length,
  products_role_clean,
  products_industry_name_clean,
  date_created,
  date_started
FROM cleaned;