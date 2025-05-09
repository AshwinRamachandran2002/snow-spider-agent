WITH base AS (
  -- 1.  Filter the required time–window
  SELECT
    *,
    -- 2a.  Temporarily protect numeric “digit, digit” patterns
    REGEXP_REPLACE(products_brand_name,
                   r'(\d),\s(\d)',          --  e.g. “2, 4”
                   r'\1##\2')               --  keep the comma‑and‑space intact via “##”
      AS temp_brand_name
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE DATE(date_created) BETWEEN '2015-01-01' AND '2015-01-31'
    AND DATE(date_started)  BETWEEN '2015-01-01' AND '2015-01-31'
),

cleaned AS (
  SELECT
    report_number,

    -- 3.  Split “reactions” / “outcomes” into trimmed arrays
    ARRAY(
      SELECT TRIM(r) FROM UNNEST(SPLIT(reactions,  ',' )) r
    ) AS reactions_array,

    ARRAY(
      SELECT TRIM(o) FROM UNNEST(SPLIT(outcomes,   ',' )) o
    ) AS outcomes_array,

    -- 4a.  Brand names : replace every “, ” with “ -- ” *except* the protected ones
    REGEXP_REPLACE(
      REGEXP_REPLACE(temp_brand_name, r',\s', ' -- '),   -- replace normal commas
      r'##', ', '                                        -- bring the protected commas back
    ) AS products_brand_name_clean,

    -- 4b.  Other list‑type fields
    REGEXP_REPLACE(products_industry_code,  r',\s', ' -- ') AS products_industry_code_clean,
    REGEXP_REPLACE(products_role,          r',\s', ' -- ') AS products_role_clean,
    REGEXP_REPLACE(products_industry_name, r',\s', ' -- ') AS products_industry_name_clean,

    -- 5.  Length metrics
    ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(products_industry_code, r',\s', ' -- '), ' -- '))
      AS industry_code_length,

    ARRAY_LENGTH(
      SPLIT(
        REGEXP_REPLACE(
          REGEXP_REPLACE(temp_brand_name, r',\s', ' -- '),  -- step‑2 brand after general replace
          r'##', ', '                                       -- restore numeric commas
        ),
        ' -- '
      )
    ) AS brand_name_length,

    -- 6.  Keep a few useful original columns
    date_created,
    date_started,
    consumer_gender,
    consumer_age,
    consumer_age_unit
  FROM base
)

SELECT *
FROM cleaned;