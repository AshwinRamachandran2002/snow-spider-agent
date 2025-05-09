/*  January-2015 Food-Event records with required cleansing & metrics  */
WITH jan_2015_events AS (
    SELECT
        "report_number",
        "reactions",
        "outcomes",
        "products_brand_name",
        "products_industry_code",
        "products_role",
        "products_industry_name"
    FROM  "FDA"."FDA_FOOD"."FOOD_EVENTS"
    WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
      AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31'
)
SELECT
    /* basic identifier */
    "report_number",

    /* split list-type fields into arrays */
    SPLIT("reactions", ',')                          AS "reaction_array",
    SPLIT("outcomes" , ',')                          AS "outcome_array",

    /* ---------- products_brand_name cleansing ---------- */
    /* 1) protect patterns like “1, 2”  → “1##2”
       2) convert remaining “, ” → “ -- ”
       3) restore protected numeric commas            */
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE("products_brand_name", '([0-9]), ([0-9])', '\\1##\\2'),
            ', ', ' -- '
        ),
        '##', ', '
    )                                                AS "products_brand_name_clean",

    /* brand_name_length after cleansing / splitting */
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(
                REGEXP_REPLACE("products_brand_name", '([0-9]), ([0-9])', '\\1##\\2'),
                ', ', ' -- '
            ),
            ' -- '
        )
    )                                                AS "brand_name_length",

    /* ---------- products_industry_code cleansing ---------- */
    REGEXP_REPLACE("products_industry_code", ', ', ' -- ')
                                                     AS "products_industry_code_clean",
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ', ', ' -- '),
            ' -- '
        )
    )                                                AS "industry_code_length",

    /* ---------- additional list-type fields cleansing ---------- */
    REGEXP_REPLACE("products_role"        , ', ', ' -- ')  AS "products_role_clean",
    REGEXP_REPLACE("products_industry_name", ', ', ' -- ') AS "products_industry_name_clean"
FROM jan_2015_events;