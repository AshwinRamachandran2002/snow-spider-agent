SELECT
    "report_number",
    "date_created",
    "date_started",
    /* split comma-separated fields into arrays */
    SPLIT("reactions", ',')                                    AS "reactions_array",
    SPLIT("outcomes",  ',')                                    AS "outcomes_array",

    /* cleanse products_brand_name (preserve digit-comma-digit patterns) */
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE("products_brand_name",
                           '([0-9])\\s*,\\s*([0-9])',
                           '\\1<<comma>>\\2'),
            ',\\s+', ' -- '),
        '<<comma>>', ',')                                      AS "products_brand_name_clean",

    /* cleanse industry-related fields */
    REGEXP_REPLACE("products_industry_code", ',\\s+', ' -- ')  AS "products_industry_code_clean",
    REGEXP_REPLACE("products_role",         ',\\s+', ' -- ')   AS "products_role_clean",
    REGEXP_REPLACE("products_industry_name",',\\s+', ' -- ')   AS "products_industry_name_clean",

    /* calculate array lengths */
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ',\\s+', ' -- ')
        , ' -- ')
    )                                                          AS "industry_code_length",

    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("products_brand_name",
                                   '([0-9])\\s*,\\s*([0-9])',
                                   '\\1<<comma>>\\2'),
                    ',\\s+', ' -- '),
                '<<comma>>', ',')
        , ' -- ')
    )                                                          AS "brand_name_length"
FROM  "FDA"."FDA_FOOD"."FOOD_EVENTS"
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31';