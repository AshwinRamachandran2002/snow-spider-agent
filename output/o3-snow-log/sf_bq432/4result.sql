SELECT
    /* basic identifiers */
    "report_number",

    /* 1) split reactions & outcomes into arrays                      */
    SPLIT("reactions" , ',')                AS "reactions_array",
    SPLIT("outcomes"  , ',')                AS "outcomes_array",

    /* 2) cleanse industry-related fields (", "  →  " -- ")            */
    REGEXP_REPLACE("products_industry_code" , ',\\s+', ' -- ')
                                             AS "industry_code_clean",
    REGEXP_REPLACE("products_role"          , ',\\s+', ' -- ')
                                             AS "role_clean",
    REGEXP_REPLACE("products_industry_name" , ',\\s+', ' -- ')
                                             AS "industry_name_clean",

    /* 3) cleanse brand name                                           */
    REGEXP_REPLACE(                                      -- step-3 : restore commas inside numeric pattern
        REGEXP_REPLACE(                                  -- step-2 : ", " → " -- "
            REGEXP_REPLACE(                              -- step-1 : protect digit , digit  →  digit#C#digit
                "products_brand_name",
                '(\\d+),\\s+(\\d+)',
                '\\1#C#\\2'
            ),
            ',\\s+',
            ' -- '
        ),
        '#C#',
        ', '
    )                                   AS "brand_name_clean",

    /* 4) length metrics                                                */
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ',\\s+', ' -- '),
            ' -- '
        )
    )                                   AS "industry_code_length",

    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(                             -- step-2
                REGEXP_REPLACE(                         -- step-1
                    "products_brand_name",
                    '(\\d+),\\s+(\\d+)',
                    '\\1#C#\\2'
                ),
                ',\\s+',
                ' -- '
            ),
            ' -- '
        )
    )                                   AS "brand_name_length",

    /* optional reference dates                                         */
    "date_created",
    "date_started"
FROM  "FDA"."FDA_FOOD"."FOOD_EVENTS"
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31';