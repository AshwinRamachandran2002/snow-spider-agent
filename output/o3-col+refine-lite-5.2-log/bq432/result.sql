WITH jan_2015 AS (
  /* base rows in the requested date window */
  SELECT
    report_number,
    reactions,
    outcomes,
    products_brand_name,
    products_industry_code,
    products_role,
    products_industry_name,
    date_created,
    date_started
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
    AND date_started  BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
),
brand_protected AS (
  /* protect digit‑comma‑digit so the comma is not later replaced */
  SELECT
    *,
    REGEXP_REPLACE(products_brand_name,
                   '(\\d),\\s*(\\d)',   /* digit , space(s) digit */
                   '\\1<comma>\\2')     /* temporary token           */
      AS brand_tmp
  FROM jan_2015
)
SELECT
  report_number,

  /* split comma‑delimited strings into arrays */
  SPLIT(reactions, ',') AS reactions_array,
  SPLIT(outcomes , ',') AS outcomes_array,

  /* cleanse brand names: replace remaining ", " then restore comma token */
  REGEXP_REPLACE(
    REGEXP_REPLACE(brand_tmp, ',\\s+', ' -- '),
    '<comma>', ','
  ) AS products_brand_name_clean,

  /* cleanse other list columns */
  REGEXP_REPLACE(products_industry_code, ',\\s+', ' -- ') AS products_industry_code_clean,
  REGEXP_REPLACE(products_role         , ',\\s+', ' -- ') AS products_role_clean,
  REGEXP_REPLACE(products_industry_name, ',\\s+', ' -- ') AS products_industry_name_clean,

  /* length metrics */
  ARRAY_LENGTH(
    SPLIT(REGEXP_REPLACE(products_industry_code, ',\\s+', ' -- '), ' -- ')
  ) AS industry_code_length,

  ARRAY_LENGTH(
    SPLIT(REGEXP_REPLACE(brand_tmp, ',\\s+', ' -- '), ' -- ')
  ) AS brand_name_length,

  /* original dates for reference */
  date_created,
  date_started
FROM brand_protected
ORDER BY report_number;