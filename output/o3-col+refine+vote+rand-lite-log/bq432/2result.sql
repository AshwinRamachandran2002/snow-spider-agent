/* Food-events reported during January 2015 – cleansed and enriched */
WITH brand_protected AS (
  /* Protect digit-comma-digit patterns in brand names */
  SELECT
    *,
    REGEXP_REPLACE(`products_brand_name`, r'(\d),(\d)', r'\1@@\2') AS brand_tmp
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE DATE(`date_created`) BETWEEN '2015-01-01' AND '2015-01-31'
    AND DATE(`date_started`)  BETWEEN '2015-01-01' AND '2015-01-31'
),
cleansed AS (
  /* Apply all requested transformations */
  SELECT
    *,
    /* brand name cleansing */
    REPLACE(REPLACE(brand_tmp, ', ', ' -- '), '@@', ',')                         AS brand_clean,
    SPLIT(REPLACE(REPLACE(brand_tmp, ', ', ' -- '), '@@', ','), ' -- ')         AS brand_array,

    /* industry-related cleansing */
    REPLACE(`products_industry_code`, ', ', ' -- ')                             AS ind_code_clean,
    SPLIT(REPLACE(`products_industry_code`, ', ', ' -- '), ' -- ')              AS ind_code_array,
    REPLACE(`products_role`,          ', ', ' -- ')                             AS ind_role_clean,
    REPLACE(`products_industry_name`, ', ', ' -- ')                             AS ind_name_clean
  FROM brand_protected
)
SELECT
  /* identifiers & dates */
  report_number,
  date_created,
  date_started,

  /* reactions & outcomes split into trimmed arrays */
  ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(reactions, ',')) r)                    AS reactions_array,
  ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes , ',')) o)                    AS outcomes_array,

  /* brand fields and metrics */
  brand_clean,
  brand_array,
  ARRAY_LENGTH(brand_array)                                                     AS brand_name_length,

  /* industry fields and metrics */
  ind_code_clean,
  ind_code_array,
  ARRAY_LENGTH(ind_code_array)                                                  AS industry_code_length,
  ind_role_clean,
  ind_name_clean
FROM cleansed;