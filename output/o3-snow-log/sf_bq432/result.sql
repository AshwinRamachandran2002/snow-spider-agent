SELECT
    "report_number",

    /* 1. split reactions & outcomes into arrays */
    SPLIT("reactions", ',')  AS "reactions_array",
    SPLIT("outcomes",  ',')  AS "outcomes_array",

    /* 2. cleanse brand name: protect digit-comma-digit, then replace other ", " with " -- " */
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            "products_brand_name",
            '([0-9]),\\s?([0-9])',
            '\\1--\\2'
        ),
        ',\\s',
        ' -- '
    ) AS "products_brand_name_clean",

    /* 3. cleanse industry-related columns */
    REGEXP_REPLACE("products_industry_code", ',\\s', ' -- ') AS "products_industry_code_clean",
    REGEXP_REPLACE("products_role",          ',\\s', ' -- ') AS "products_role_clean",
    REGEXP_REPLACE("products_industry_name", ',\\s', ' -- ') AS "products_industry_name_clean",

    /* 4. length of the cleaned industry-code / brand-name lists */
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ',\\s', ' -- '),
            ' -- '
        )
    ) AS "industry_code_length",

    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(
                REGEXP_REPLACE("products_brand_name", '([0-9]),\\s?([0-9])', '\\1--\\2'),
                ',\\s',
                ' -- '
            ),
            ' -- '
        )
    ) AS "brand_name_length"

FROM "FDA"."FDA_FOOD"."FOOD_EVENTS"
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31';