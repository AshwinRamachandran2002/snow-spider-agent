SELECT
  -- identifiers
  report_number                                            AS event_id,
  DATE(date_created)                                       AS date_created,
  DATE(date_started)                                       AS date_started,

  -- split comma‑separated strings into trimmed arrays
  ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(reactions,  ',')) AS r)  AS reactions,
  ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes ,  ',')) AS o)  AS outcomes,

  -- cleansed textual columns
  brand_clean                                              AS products_brand_name,
  ind_code_clean                                           AS products_industry_code,
  role_clean                                               AS products_role,
  ind_name_clean                                           AS products_industry_name,

  -- derived lengths
  ARRAY_LENGTH(SPLIT(ind_code_clean , ' -- '))             AS industry_code_length,
  ARRAY_LENGTH(SPLIT(brand_clean     , ' -- '))            AS brand_name_length
FROM (
  SELECT
    report_number,
    date_created,
    date_started,
    reactions,
    outcomes,

    /* --------------------------------------------------------------------
       Cleansing rules
       -------------------------------------------------------------------- */

    /* products_brand_name
       1. Protect digit,comma,digit with temporary "@@".
       2. Replace remaining ", " (comma + spaces) with " -- ".
       3. Restore "@@" back to ", ".
    */
    REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(products_brand_name, r'(\d),\s*(\d)', r'\1@@\2'),
        r',\s+', ' -- '),
      '@@', ', ')                                         AS brand_clean,

    /* products_industry_code / products_role / products_industry_name
       Simple replacement of ", " + optional spaces with " -- "
    */
    REGEXP_REPLACE(products_industry_code , r',\s+', ' -- ') AS ind_code_clean,
    REGEXP_REPLACE(products_role          , r',\s+', ' -- ') AS role_clean,
    REGEXP_REPLACE(products_industry_name , r',\s+', ' -- ') AS ind_name_clean
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE date_created BETWEEN '2015-01-01' AND '2015-01-31'
    AND date_started BETWEEN '2015-01-01' AND '2015-01-31'
)
ORDER BY event_id;