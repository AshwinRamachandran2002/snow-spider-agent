-- Food events between 01‑Jan‑2015 and 31‑Jan‑2015
-- Cleansing and derived‑field logic applied
WITH base AS (
  SELECT
    report_number,

    /* 1. split REACTIONS & OUTCOMES into arrays */
    ARRAY(
      SELECT TRIM(r)
      FROM UNNEST(SPLIT(reactions, ',')) AS r
    ) AS reactions_array,

    ARRAY(
      SELECT TRIM(o)
      FROM UNNEST(SPLIT(outcomes, ',')) AS o
    ) AS outcomes_array,

    /* 2. brand names – protect “digit , space digit” commas,
          then replace remaining ", " with " -- ",
          finally restore the protected commas                       */
    REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name, r'(\\d),\\s(\\d)', r'\\1<<comma>>\\2'),
        ', ',
        ' -- '
      ),
      '<<comma>>',
      ', '
    ) AS products_brand_name_clean,

    /* 3. simple “, ” → “ -- ” replacements on other list columns */
    REGEXP_REPLACE(products_industry_code, ', ', ' -- ') AS products_industry_code_clean,
    REGEXP_REPLACE(products_role,          ', ', ' -- ') AS products_role_clean,
    REGEXP_REPLACE(products_industry_name, ', ', ' -- ') AS products_industry_name_clean,

    /* 4. original fields */
    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
    AND date_started  BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
)

SELECT
  report_number,
  reactions_array,
  outcomes_array,
  products_brand_name_clean,
  products_industry_code_clean,
  products_role_clean,
  products_industry_name_clean,
  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  /* 5. derived lengths */
  ARRAY_LENGTH(SPLIT(products_industry_code_clean, ' -- ')) AS industry_code_length,
  ARRAY_LENGTH(SPLIT(products_brand_name_clean,      ' -- ')) AS brand_name_length
FROM base;