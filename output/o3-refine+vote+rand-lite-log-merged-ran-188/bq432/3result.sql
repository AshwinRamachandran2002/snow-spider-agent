-- food events during 1‒31 Jan 2015 with requested cleansing and metrics
WITH cleaned AS (
  SELECT
    report_number,

    -- split semantically on “,”
    ARRAY(
      SELECT TRIM(r)
      FROM UNNEST(SPLIT(reactions,  ','  )) r
      WHERE TRIM(r) <> ''
    ) AS reactions,

    ARRAY(
      SELECT TRIM(o)
      FROM UNNEST(SPLIT(outcomes,   ','  )) o
      WHERE TRIM(o) <> ''
    ) AS outcomes,

    -- replace “, ” that act as list‑separators with “ -- ”
    -- (commas inside numbers, e.g. “2,000”, are kept because they have no space)
    REGEXP_REPLACE(products_brand_name,   r',\s+', ' -- ') AS products_brand_name,
    REGEXP_REPLACE(products_industry_code, r',\s+', ' -- ') AS products_industry_code,
    REGEXP_REPLACE(products_role,          r',\s+', ' -- ') AS products_role,
    REGEXP_REPLACE(products_industry_name, r',\s+', ' -- ') AS products_industry_name,

    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
    AND date_started BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
)

SELECT
  report_number,
  reactions,
  outcomes,
  products_brand_name,
  products_industry_code,
  products_role,
  products_industry_name,
  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  -- metric columns
  ARRAY_LENGTH(SPLIT(products_industry_code, ' -- ')) AS industry_code_length,
  ARRAY_LENGTH(SPLIT(products_brand_name,     ' -- ')) AS brand_name_length
FROM cleaned;