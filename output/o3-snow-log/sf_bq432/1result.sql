SELECT
    /* core identifiers */
    "report_number",
    
    /* -------- cleanse & transform list fields -------- */
    SPLIT("reactions", ',')                          AS "reaction_array",
    SPLIT("outcomes",  ',')                          AS "outcome_array",

    /* ---- products_brand_name (3-step placeholder technique) ---- */
    REGEXP_REPLACE(                                  /* Step-3 : restore comma-space */
        REGEXP_REPLACE(                              /* Step-2 : replace ,␠ with ' -- ' */
            REGEXP_REPLACE(                          /* Step-1 : protect digit,␠digit */
                "products_brand_name",
                '([0-9]),\\s([0-9])',
                '\\1§\\2'
            ),
            ',\\s',
            ' -- '
        ),
        '([0-9])§([0-9])',
        '\\1, \\2'
    ) AS "clean_brand_name",

    /* other list fields */
    REGEXP_REPLACE("products_industry_code", ',\\s', ' -- ') AS "clean_industry_code",
    REGEXP_REPLACE("products_role",         ',\\s', ' -- ') AS "clean_role",
    REGEXP_REPLACE("products_industry_name",',\\s', ' -- ') AS "clean_industry_name",
    
    /* -------- derived length metrics -------- */
    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE("products_industry_code", ',\\s', ' -- '),
            ' -- '
        )
    ) AS "industry_code_length",

    ARRAY_SIZE(
        SPLIT(
            REGEXP_REPLACE(                          /* Step-3 restore */
                REGEXP_REPLACE(                      /* Step-2 replace */
                    REGEXP_REPLACE(                  /* Step-1 protect */
                        "products_brand_name",
                        '([0-9]),\\s([0-9])',
                        '\\1§\\2'
                    ),
                    ',\\s',
                    ' -- '
                ),
                '([0-9])§([0-9])',
                '\\1, \\2'
            ),
            ' -- '
        )
    ) AS "brand_name_length",
    
    /* -------- pass-through fields -------- */
    "date_created",
    "date_started",
    "consumer_gender",
    "consumer_age",
    "consumer_age_unit"

FROM "FDA"."FDA_FOOD"."FOOD_EVENTS"
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
  AND "date_started" BETWEEN '2015-01-01' AND '2015-01-31';