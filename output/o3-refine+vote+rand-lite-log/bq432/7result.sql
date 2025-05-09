-- Food‑events in January 2015 with all requested cleansing/derivative columns
WITH jan15 AS (
  SELECT
    *,
    -- step‑1 : temporarily protect “digit, digit” patterns in brand names
    REGEXP_REPLACE(products_brand_name,
                   r'(\d),\s+(\d)',
                   r'\1<<NUM_COMMA>>\2')                      AS brand_tmp
  FROM `bigquery-public-data.fda_food.food_events`
  WHERE DATE(date_created) BETWEEN '2015-01-01' AND '2015-01-31'
    AND DATE(date_started) BETWEEN '2015-01-01' AND '2015-01-31'
)

SELECT
  report_number,

  /* -------------------------------  arrays  ------------------------------- */
  -- reactions
  ARRAY(
    SELECT TRIM(r)
    FROM UNNEST(SPLIT(COALESCE(reactions,''), ',')) r
    WHERE TRIM(r) <> ''
  )                                                   AS reactions_array,

  -- outcomes
  ARRAY(
    SELECT TRIM(o)
    FROM UNNEST(SPLIT(COALESCE(outcomes,''), ',')) o
    WHERE TRIM(o) <> ''
  )                                                   AS outcomes_array,

  -- products_brand_name  (special numeric protection → replace → split)
  ARRAY(
    SELECT TRIM(b)
    FROM UNNEST(
      SPLIT(
        REPLACE(                      -- put comma back after global replace
          REPLACE(brand_tmp, ', ', ' -- '),     -- replace un‑protected “, ”
          '<<NUM_COMMA>>', ', '
        ),
        ' -- '
      )
    ) b
    WHERE TRIM(b) <> ''
  )                                                   AS products_brand_array,

  -- products_industry_code
  ARRAY(
    SELECT TRIM(c)
    FROM UNNEST(
      SPLIT(REPLACE(COALESCE(products_industry_code,''), ', ', ' -- '), ' -- ')
    ) c
    WHERE TRIM(c) <> ''
  )                                                   AS products_industry_code_array,

  -- products_role
  ARRAY(
    SELECT TRIM(rp)
    FROM UNNEST(
      SPLIT(REPLACE(COALESCE(products_role,''), ', ', ' -- '), ' -- ')
    ) rp
    WHERE TRIM(rp) <> ''
  )                                                   AS products_role_array,

  -- products_industry_name
  ARRAY(
    SELECT TRIM(nm)
    FROM UNNEST(
      SPLIT(REPLACE(COALESCE(products_industry_name,''), ', ', ' -- '), ' -- ')
    ) nm
    WHERE TRIM(nm) <> ''
  )                                                   AS products_industry_name_array,

  /* ---------------------------  original columns  ------------------------- */
  date_created,
  date_started,
  consumer_gender,
  consumer_age,
  consumer_age_unit,

  /* -------------------------  derived statistics  ------------------------- */
  ARRAY_LENGTH(
    SPLIT(REPLACE(COALESCE(products_industry_code,''), ', ', ' -- '), ' -- ')
  )                                                   AS industry_code_length,

  ARRAY_LENGTH(
    SPLIT(
      REPLACE(
        REPLACE(brand_tmp, ', ', ' -- '),
        '<<NUM_COMMA>>', ', '
      ),
      ' -- '
    )
  )                                                   AS brand_name_length

FROM jan15;