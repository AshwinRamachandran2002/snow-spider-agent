-- Food events reported (created AND started) between 1–31 Jan 2015
-- with requested data-cleansing and extra length metrics
WITH base AS (
  SELECT
    report_number,
    date_created,
    date_started,
    reactions,
    outcomes,
    products_brand_name,
    products_industry_code,
    products_role,
    products_industry_name
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started  BETWEEN '2015-01-01' AND '2015-01-31'
),

/* -------------------------------------------
   1. Prepare CLEAN versions of the 4 “code/name” columns
   ------------------------------------------- */
cleaned AS (
  SELECT
    *,
    
    -- products_brand_name: protect numeric “digit, digit” patterns first
    REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1||\2')     AS brand_tmp,
    
    -- simple replacements (”, “ → “ -- ”) for the 3 other columns
    REGEXP_REPLACE(products_industry_code,  ',\\s', ' -- ')             AS ind_code_clean,
    REGEXP_REPLACE(products_role,          ',\\s', ' -- ')             AS role_clean,
    REGEXP_REPLACE(products_industry_name, ',\\s', ' -- ')             AS ind_name_clean
  FROM base
),

/* -------------------------------------------
   2. Finalise brand name cleaning & build arrays
   ------------------------------------------- */
final AS (
  SELECT
    report_number,
    date_created,
    date_started,
    
    /* reactions / outcomes as trimmed arrays */
    ARRAY(
      SELECT TRIM(r)
      FROM UNNEST(SPLIT(reactions,  ',')) r
      WHERE TRIM(r) IS NOT NULL AND TRIM(r) <> ''
    ) AS reactions_array,
    
    ARRAY(
      SELECT TRIM(o)
      FROM UNNEST(SPLIT(outcomes,   ',')) o
      WHERE TRIM(o) IS NOT NULL AND TRIM(o) <> ''
    ) AS outcomes_array,
    
    /* products_brand_name cleansed */
    /* 1. after numeric-pattern placeholder, replace remaining “, ”  */
    /* 2. restore the placeholder (“||”) back to “, ”               */
    REGEXP_REPLACE(
      REGEXP_REPLACE(brand_tmp, ',\\s', ' -- '),           -- general replace
      '\\|\\|', ', '                                       -- restore numeric commas
    ) AS products_brand_name_clean,
    
    ind_code_clean        AS products_industry_code_clean,
    role_clean            AS products_role_clean,
    ind_name_clean        AS products_industry_name_clean,
    
    /* length metrics */
    ARRAY_LENGTH(
      SPLIT(IFNULL(ind_code_clean,''), ' -- ')
    ) AS industry_code_length,
    
    ARRAY_LENGTH(
      SPLIT(
        REGEXP_REPLACE(
          REGEXP_REPLACE(brand_tmp, ',\\s', ' -- '),
          '\\|\\|', ', '
        ),
        ' -- '
      )
    ) AS brand_name_length
  FROM cleaned
)

SELECT *
FROM final
ORDER BY date_created, report_number;