-- Food events reported and started between 01‑Jan‑2015 and 31‑Jan‑2015
-- with requested data‑cleansing steps applied
SELECT
  /* identifiers & dates */
  report_number,
  date_created,
  date_started,

  /* basic consumer info */
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  /* reactions & outcomes split into arrays */
  SPLIT(REGEXP_REPLACE(reactions , r',\s*', ','),  ',')     AS reactions_array,
  SPLIT(REGEXP_REPLACE(outcomes  , r',\s*', ','),  ',')     AS outcomes_array,

  /* cleansed product fields                                                  */
  -- 1. brand names  (preserve digit‑comma‑digit patterns, split on  " -- ")
  REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1@@\2')  -- protect digit,comma,digit
      , r',\s+' , ' -- ' )                                               -- replace other “, ”
  , r'(\d)@@(\d)', r'\1, \2')                                            -- restore protected patterns
    AS products_brand_name_clean,

  REGEXP_REPLACE(products_industry_code , r',\s+' , ' -- ') AS products_industry_code_clean,
  REGEXP_REPLACE(products_role          , r',\s+' , ' -- ') AS products_role_clean,
  REGEXP_REPLACE(products_industry_name , r',\s+' , ' -- ') AS products_industry_name_clean,

  /* derived arrays for size metrics */
  SPLIT(
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1@@\2'),
        r',\s+',' -- ' ),
      r'(\d)@@(\d)', r'\1, \2')
    , ' -- ')                                                            AS products_brand_name_array,

  SPLIT(REGEXP_REPLACE(products_industry_code , r',\s+' , ' -- '), ' -- ') AS industry_code_array,

  /* array lengths */
  ARRAY_LENGTH(
    SPLIT(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1@@\2'),
          r',\s+',' -- ' ),
        r'(\d)@@(\d)', r'\1, \2')
      , ' -- ')
  ) AS brand_name_length,

  ARRAY_LENGTH(
    SPLIT(REGEXP_REPLACE(products_industry_code , r',\s+' , ' -- '), ' -- ')
  ) AS industry_code_length

FROM `bigquery-public-data.fda_food.food_events`
WHERE
      date_created BETWEEN '2015-01-01' AND '2015-01-31'
  AND date_started  BETWEEN '2015-01-01' AND '2015-01-31';