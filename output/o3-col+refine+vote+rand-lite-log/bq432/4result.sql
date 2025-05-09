-- Food-event records for Jan 1 – Jan 31 2015 with required cleansing
WITH raw AS (
  SELECT *
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE DATE(`date_created`) BETWEEN '2015-01-01' AND '2015-01-31'
    AND DATE(`date_started`) BETWEEN '2015-01-01' AND '2015-01-31'
),
cleansed AS (
  SELECT
    report_number,

    -- split & trim comma-separated strings
    ARRAY(SELECT TRIM(x) FROM UNNEST(SPLIT(reactions,  ',')) AS x) AS reactions_array,
    ARRAY(SELECT TRIM(x) FROM UNNEST(SPLIT(outcomes,   ',')) AS x) AS outcomes_array,

    -- brand name: keep digit-comma-digit patterns, then replace “, ” with “ -- ”
    REGEXP_REPLACE(
      REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1@@\2'),
      r',\s', ' -- '
    ) AS brand_name_clean,

    -- other product fields: simply replace “, ” with “ -- ”
    REGEXP_REPLACE(products_industry_code, r',\s', ' -- ') AS industry_code_clean,
    REGEXP_REPLACE(products_role,          r',\s', ' -- ') AS role_clean,
    REGEXP_REPLACE(products_industry_name, r',\s', ' -- ') AS industry_name_clean,

    date_created,
    date_started
  FROM raw
)
SELECT
  report_number,
  reactions_array,
  outcomes_array,

  -- build final arrays
  SPLIT(brand_name_clean,      ' -- ') AS products_brand_name_array,
  SPLIT(industry_code_clean,   ' -- ') AS products_industry_code_array,
  SPLIT(role_clean,            ' -- ') AS products_role_array,
  SPLIT(industry_name_clean,   ' -- ') AS products_industry_name_array,

  -- derived lengths
  ARRAY_LENGTH(SPLIT(brand_name_clean,    ' -- ')) AS brand_name_length,
  ARRAY_LENGTH(SPLIT(industry_code_clean, ' -- ')) AS industry_code_length,

  date_created,
  date_started
FROM cleansed;