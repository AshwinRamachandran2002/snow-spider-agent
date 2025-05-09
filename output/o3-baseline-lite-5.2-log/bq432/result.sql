WITH base AS (
  SELECT
    *
    -- protect numeric patterns like "2, 4" first,
    ,REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name,
                       r'(\d),\s*(\d)', r'\1<<comma>>\2'),   -- protect
        r',\s+', ' -- ')                                               -- replace others
      AS brand_temp
    ,REGEXP_REPLACE(products_industry_code , r',\s+', ' -- ') AS industry_code_temp
    ,REGEXP_REPLACE(products_role          , r',\s+', ' -- ') AS role_temp
    ,REGEXP_REPLACE(products_industry_name , r',\s+', ' -- ') AS industry_name_temp
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
    AND date_started BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
)

SELECT
  report_number,

  -- split reactions / outcomes into arrays
  (SELECT ARRAY_AGG(TRIM(r)) FROM UNNEST(SPLIT(reactions,  ',')) r)   AS reactions,
  (SELECT ARRAY_AGG(TRIM(o)) FROM UNNEST(SPLIT(outcomes ,  ',')) o)   AS outcomes,

  -- brand names (restore protected commas after split)
  (SELECT ARRAY_AGG(TRIM(REGEXP_REPLACE(b,'<<comma>>',', ')))
     FROM UNNEST(SPLIT(brand_temp,' -- ')) b)                         AS products_brand_name,

  (SELECT ARRAY_AGG(TRIM(i)) FROM UNNEST(SPLIT(industry_code_temp,' -- ')) i)
                                                                      AS products_industry_code,
  (SELECT ARRAY_AGG(TRIM(r)) FROM UNNEST(SPLIT(role_temp          ,' -- ')) r)
                                                                      AS products_role,
  (SELECT ARRAY_AGG(TRIM(n)) FROM UNNEST(SPLIT(industry_name_temp ,' -- ')) n)
                                                                      AS products_industry_name,

  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  ARRAY_LENGTH(SPLIT(industry_code_temp,' -- '))                      AS industry_code_length,
  ARRAY_LENGTH(SPLIT(brand_temp        ,' -- '))                      AS brand_name_length
FROM base;