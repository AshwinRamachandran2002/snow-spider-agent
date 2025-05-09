/*  Food events between 1–31 Jan 2015 with requested cleansing  */
WITH filtered AS (   -- step 1: time window + basic arrays
    SELECT
        report_number,
        -- split “reactions” / “outcomes” on commas
        ARRAY(SELECT TRIM(r) FROM UNNEST(SPLIT(reactions, ',' )) r) AS reactions_arr,
        ARRAY(SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes , ',' )) o) AS outcomes_arr,
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
    WHERE date_created BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
      AND date_started  BETWEEN DATE '2015-01-01' AND DATE '2015-01-31'
),
brand_preserve_numeric AS (      -- step 2: protect “digit, digit” patterns
    SELECT
        *,
        REGEXP_REPLACE(products_brand_name, r'(\d), (\d)', r'\1@@\2') AS brand_tmp
    FROM filtered
),
after_replacements AS (          -- step 3: do required “, ” → “ -- ” swaps
    SELECT
        report_number,
        reactions_arr,
        outcomes_arr,
        REPLACE(brand_tmp, ', ', ' -- ')                       AS brand_step,
        REPLACE(products_industry_code , ', ', ' -- ')         AS industry_code_clean,
        REPLACE(products_role          , ', ', ' -- ')         AS products_role_clean,
        REPLACE(products_industry_name , ', ', ' -- ')         AS industry_name_clean,
        date_created,
        date_started,
        consumer_gender,
        consumer_age,
        consumer_age_unit
    FROM brand_preserve_numeric
)
SELECT
    report_number,
    reactions_arr                         AS reactions,
    outcomes_arr                          AS outcomes,
    REPLACE(brand_step, '@@', ', ')       AS products_brand_name,
    industry_code_clean                   AS products_industry_code,
    products_role_clean                   AS products_role,
    industry_name_clean                   AS products_industry_name,
    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit,
    ARRAY_LENGTH(SPLIT(industry_code_clean , ' -- '))          AS industry_code_length,
    ARRAY_LENGTH(SPLIT(REPLACE(brand_step, '@@', ', ') , ' -- ')) AS brand_name_length
FROM after_replacements;