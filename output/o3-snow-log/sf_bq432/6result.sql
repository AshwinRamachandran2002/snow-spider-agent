SELECT
    "report_number",
    "date_created",
    "date_started",

    /* 1. split “reactions” & “outcomes” into arrays */
    SPLIT("reactions",  ',') AS "reactions_array",
    SPLIT("outcomes",   ',') AS "outcomes_array",

    /* 2. cleanse “products_brand_name” (preserve numeric commas, change others to ` -- `) */
    REPLACE(
        REGEXP_REPLACE("products_brand_name", '(\\d),(\\d)', '\\1\\2'),
        ', ',
        ' -- '
    ) AS "products_brand_name_clean",

    /* 3. brand-name list length */
    ARRAY_SIZE(
        SPLIT(
            REPLACE(
                REGEXP_REPLACE("products_brand_name", '(\\d),(\\d)', '\\1\\2'),
                ', ',
                ' -- '
            ),
            ' -- '
        )
    ) AS "brand_name_length",

    /* 4. cleanse industry-code + length */
    REPLACE("products_industry_code", ', ', ' -- ')                AS "products_industry_code_clean",
    ARRAY_SIZE(
        SPLIT(
            REPLACE("products_industry_code", ', ', ' -- '),
            ' -- '
        )
    ) AS "industry_code_length",

    /* 5. cleanse role & industry-name */
    REPLACE("products_role",          ', ', ' -- ') AS "products_role_clean",
    REPLACE("products_industry_name", ', ', ' -- ') AS "products_industry_name_clean",

    /* 6. other consumer fields */
    "consumer_gender",
    "consumer_age",
    "consumer_age_unit"

FROM FDA.FDA_FOOD."FOOD_EVENTS"
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31';