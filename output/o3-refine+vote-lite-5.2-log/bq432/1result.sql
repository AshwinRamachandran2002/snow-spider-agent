-- Food events between 1 – 31 Jan 2015 with requested cleansing steps
WITH src AS (
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
    consumer_age_unit
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
),

-- 1. protect numeric “#, #” patterns in brand names with a placeholder
brand_protected AS (
  SELECT
    src.*,
    REGEXP_REPLACE(products_brand_name,
                   r'(\d),\s+(\d)',
                   r'\1<<comma_placeholder>>\2') AS brand_pl
  FROM src
),

-- 2. replace remaining “, ” with “ -- ” in required fields
cleansed AS (
  SELECT
    report_number,
    reactions,
    outcomes,
    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit,

    -- brand name after step‑2, placeholder still present
    REPLACE(brand_pl, ', ', ' -- ')                                AS brand_step2,

    REPLACE(products_industry_code, ', ', ' -- ')                  AS industry_code_clean,
    REPLACE(products_role,          ', ', ' -- ')                  AS products_role_clean,
    REPLACE(products_industry_name, ', ', ' -- ')                  AS products_industry_name_clean
  FROM brand_protected
),

-- 3. final fixes & derived columns
final AS (
  SELECT
    report_number,

    -- split to arrays and trim spaces
    ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(COALESCE(reactions ,''), ',')) r)  AS reactions_array,
    ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(COALESCE(outcomes  ,''), ',')) o)  AS outcomes_array,

    -- restore numeric commas in brand names
    REPLACE(brand_step2, '<<comma_placeholder>>', ', ')           AS products_brand_name_clean,
    industry_code_clean                                           AS products_industry_code_clean,
    products_role_clean,
    products_industry_name_clean,

    -- length metrics
    IFNULL(ARRAY_LENGTH(SPLIT(industry_code_clean, ' -- ')),0)    AS industry_code_length,
    IFNULL(ARRAY_LENGTH(SPLIT(REPLACE(brand_step2,
                                      '<<comma_placeholder>>',
                                      ', '), ' -- ')),0)          AS brand_name_length,

    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit
  FROM cleansed
)

SELECT *
FROM final;