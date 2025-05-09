SELECT
    "report_number",
    "date_created",
    "date_started",

    /* split to arrays ---------------------------------------------------*/
    SPLIT("reactions" , ',')                     AS "reactions_array",
    SPLIT("outcomes"  , ',')                     AS "outcomes_array",

    /* ------------------- brand-name cleansing --------------------------*/
    /*  1) protect digit , digit with a placeholder (#)                   */
    /*  2) convert remaining ", " to " -- "                               */
    /*  3) restore the numeric comma                                      */
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE("products_brand_name",
                           '([0-9]),\\s*([0-9])', '\\1#\\2'),
            ',\\s+', ' -- '),
        '#', ', '
    )                                          AS "brand_name_clean",

    /* length of brand list ---------------------------------------------*/
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("products_brand_name",
                                   '([0-9]),\\s*([0-9])', '\\1#\\2'),
                    ',\\s+', ' -- '),
                '#', ', '
            ),
            ' -- ')
    )                                          AS "brand_name_length",

    /* ---------------- industry-code cleansing -------------------------*/
    REGEXP_REPLACE("products_industry_code", ',\\s+', ' -- ')
                                               AS "industry_code_clean",
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ',\\s+', ' -- '),
            ' -- ')
    )                                          AS "industry_code_length",

    /* additional text fields -------------------------------------------*/
    REGEXP_REPLACE("products_role",          ',\\s+', ' -- ')
                                               AS "products_role_clean",
    REGEXP_REPLACE("products_industry_name", ',\\s+', ' -- ')
                                               AS "industry_name_clean"

FROM   FDA.FDA_FOOD.FOOD_EVENTS
WHERE  "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND  "date_started" BETWEEN '2015-01-01' AND '2015-01-31';