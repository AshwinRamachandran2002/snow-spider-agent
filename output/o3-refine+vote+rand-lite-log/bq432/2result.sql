WITH prep AS (
  SELECT
    report_number,

    -- split & trim reactions / outcomes
    ARRAY(
      SELECT TRIM(part)
      FROM UNNEST(SPLIT(reactions, ',')) part
      WHERE TRIM(part) <> ''
    )                                              AS reactions_array,

    ARRAY(
      SELECT TRIM(part)
      FROM UNNEST(SPLIT(outcomes, ',')) part
      WHERE TRIM(part) <> ''
    )                                              AS outcomes_array,

    -- handle special numeric pattern d", "d  → protect with <comma> token first
    REGEXP_REPLACE(
      REGEXP_REPLACE(COALESCE(products_brand_name,''), r'(\d), (\d)', r'\1<comma>\2'),
      r', ',
      ' -- '
    )                                              AS brand_name_tmp,

    -- simple “, ” → “ -- ” replacements
    REGEXP_REPLACE(COALESCE(products_industry_code,''), r', ', ' -- ')  AS industry_code_clean,
    REGEXP_REPLACE(COALESCE(products_role,''),          r', ', ' -- ')  AS products_role_clean,
    REGEXP_REPLACE(COALESCE(products_industry_name,''), r', ', ' -- ')  AS industry_name_clean,

    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  report_number,
  reactions_array,
  outcomes_array,

  -- restore protected numeric commas
  REPLACE(brand_name_tmp, '<comma>', ', ')                        AS products_brand_name,

  industry_code_clean                                             AS products_industry_code,
  products_role_clean                                             AS products_role,
  industry_name_clean                                             AS products_industry_name,

  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  -- lengths
  CASE
    WHEN industry_code_clean = '' THEN 0
    ELSE ARRAY_LENGTH(SPLIT(industry_code_clean, ' -- '))
  END                                                             AS industry_code_length,

  CASE
    WHEN brand_name_tmp = '' THEN 0
    ELSE ARRAY_LENGTH(SPLIT(REPLACE(brand_name_tmp, '<comma>', ', '), ' -- '))
  END                                                             AS brand_name_length
FROM prep;