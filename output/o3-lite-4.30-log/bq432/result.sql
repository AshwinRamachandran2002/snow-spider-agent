/* Food‑events in January 2015 with the requested cleansing */
SELECT
  report_number                                                                 AS event_id,
  date_created,
  date_started,

  /* split & trim reactions / outcomes into arrays */
  ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(reactions, ',')) AS r)                 AS reactions,
  ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes , ',')) AS o)                 AS outcomes,

  products_brand_name_clean                                                    AS products_brand_name,
  products_industry_code_clean                                                 AS products_industry_code,
  products_role_clean                                                          AS products_role,
  products_industry_name_clean                                                 AS products_industry_name,

  ARRAY_LENGTH(SPLIT(products_industry_code_clean, ' -- '))                    AS industry_code_length,
  ARRAY_LENGTH(SPLIT(products_brand_name_clean,      ' -- '))                  AS brand_name_length
FROM (
  SELECT
    report_number,
    date_created,
    date_started,
    reactions,
    outcomes,

    /* --- brand name: protect numeric commas, convert others --- */
    REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name, r'(\d+), (\d+)', r'\1#\2'),
        ', ', ' -- '
      ),
      '#', ', '
    ) AS products_brand_name_clean,

    /* --- replace ", " with " -- " in remaining fields --- */
    REPLACE(products_industry_code , ', ', ' -- ') AS products_industry_code_clean,
    REPLACE(products_role          , ', ', ' -- ') AS products_role_clean,
    REPLACE(products_industry_name , ', ', ' -- ') AS products_industry_name_clean
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
);