-- Cleaned FDA food-events rows for 01-Jan-2015 – 31-Jan-2015
WITH base AS (
  SELECT *
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
),

brand_fix AS (  -- shield “digit , digit” so later comma-replacement won’t split numbers
  SELECT
    *,
    REGEXP_REPLACE(products_brand_name,
                   r'(\d),(\d)',            -- e.g., “1,000” → “1NUMCOMMA000”
                   r'\1NUMCOMMA\2') AS brand_tmp
  FROM base
)

SELECT
  report_number,

  -- arrays
  SPLIT(reactions, ',') AS reactions_array,
  SPLIT(outcomes , ',') AS outcomes_array,

  -- cleaned brand name
  REPLACE(
    REGEXP_REPLACE(brand_tmp, ',\\s+', ' -- '),  -- normal “, ” → “ -- ”
    'NUMCOMMA', ',')                            -- restore numeric commas
    AS products_brand_name_clean,

  -- industry-related fields cleaned
  REGEXP_REPLACE(products_industry_code, ',\\s+', ' -- ')
    AS products_industry_code_clean,
  REGEXP_REPLACE(products_role,          ',\\s+', ' -- ')
    AS products_role_clean,
  REGEXP_REPLACE(products_industry_name, ',\\s+', ' -- ')
    AS products_industry_name_clean,

  -- derived lengths
  ARRAY_LENGTH(
    SPLIT(
      REGEXP_REPLACE(products_industry_code, ',\\s+', ' -- '),
      ' -- ')
  ) AS industry_code_length,

  ARRAY_LENGTH(
    SPLIT(
      REPLACE(
        REGEXP_REPLACE(brand_tmp, ',\\s+', ' -- '),
        'NUMCOMMA', ','),
      ' -- ')
  ) AS brand_name_length,

  -- reference dates
  date_created,
  date_started
FROM brand_fix
ORDER BY report_number;