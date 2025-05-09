WITH prep AS (
  -- 1)  Filter rows created AND started in Jan-2015  
  -- 2)  Build a fully-cleansed `brand_clean` column  
  SELECT
    report_number,
    reactions,
    outcomes,
    products_industry_code,
    products_role,
    products_industry_name,
    date_created,
    date_started,
    REGEXP_REPLACE(                                   -- step-2: turn remaining “, ”
      REGEXP_REPLACE(                                 -- step-1: protect “digit, digit”
        products_brand_name,
        r'(\d),\s(\d)',
        r'\1--\2'
      ),
      r',\s',
      ' -- '
    ) AS brand_clean
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  report_number,

  -- reactions / outcomes split into trimmed arrays
  ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(reactions, ',')) AS r)  AS reactions_arr,
  ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes , ',')) AS o)  AS outcomes_arr,

  -- cleansed textual columns
  brand_clean                                                   AS products_brand_name_clean,
  REPLACE(products_industry_code , ', ', ' -- ')                AS products_industry_code_clean,
  REPLACE(products_role          , ', ', ' -- ')                AS products_role_clean,
  REPLACE(products_industry_name , ', ', ' -- ')                AS products_industry_name_clean,

  -- derived arrays
  SPLIT(REPLACE(products_industry_code , ', ', ' -- '), ' -- ') AS industry_code_arr,
  SPLIT(brand_clean, ' -- ')                                    AS brand_name_arr,

  -- length metrics
  ARRAY_LENGTH(SPLIT(REPLACE(products_industry_code , ', ', ' -- '), ' -- '))
                                                                 AS industry_code_length,
  ARRAY_LENGTH(SPLIT(brand_clean, ' -- '))                      AS brand_name_length,

  -- audit columns
  date_created,
  date_started
FROM prep;