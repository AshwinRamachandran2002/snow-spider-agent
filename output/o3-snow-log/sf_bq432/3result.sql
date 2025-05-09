/*  Food-events between 01-Jan-2015 and 31-Jan-2015
    ‑ split “reactions” & “outcomes” into arrays
    ‑ cleanse the 4 product-related string columns
    ‑ derive brand_name_length & industry_code_length                               */

WITH base AS (      --------------------------------------------------------------- 
    SELECT
        "report_number",

        /* 1.  arrays for reactions / outcomes */
        SPLIT("reactions" , ',')                       AS "reactions_arr",
        SPLIT("outcomes"  , ',')                       AS "outcomes_arr",

        /* 2.  protect digit , digit pattern in brand name, then hold in brand_tmp  */
        REGEXP_REPLACE("products_brand_name",
                       '([0-9]), ([0-9])', '\\1@@\\2') AS "brand_tmp",

        /* 3.  simple “, ” → “ -- ” replacement in the three other columns          */
        REPLACE("products_industry_code", ', ', ' -- ') AS "industry_code_clean",
        REPLACE("products_role"        , ', ', ' -- ') AS "products_role_clean",
        REPLACE("products_industry_name", ', ', ' -- ') AS "industry_name_clean"
    FROM FDA.FDA_FOOD.FOOD_EVENTS
    WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31'
      AND "date_started"  BETWEEN '2015-01-01' AND '2015-01-31'
),
brand_step AS (     --------------------------------------------------------------- 
    /* now finish cleansing brand name by turning the remaining comma-space pairs
       into “ -- ” (protected “@@” commas remain intact)                            */
    SELECT
        *,
        REPLACE("brand_tmp", ', ', ' -- ')            AS "brand_tmp2"
    FROM base
)
SELECT
    /* basic identifiers */
    "report_number",

    /* arrays + their lengths */
    "reactions_arr",
    ARRAY_SIZE("reactions_arr")                       AS "reactions_length",
    "outcomes_arr",
    ARRAY_SIZE("outcomes_arr")                        AS "outcomes_length",

    /* final cleansed brand name: restore the protected numeric commas             */
    REPLACE("brand_tmp2", '@@', ', ')                 AS "products_brand_name",

    /* derived lengths after the cleansing steps                                   */
    ARRAY_SIZE(SPLIT("brand_tmp2", ','))              AS "brand_name_length",

    /* remaining cleansed product columns + length for industry codes              */
    "industry_code_clean"                            AS "products_industry_code",
    ARRAY_SIZE(SPLIT("industry_code_clean", ','))     AS "industry_code_length",
    "products_role_clean"                            AS "products_role",
    "industry_name_clean"                            AS "products_industry_name"
FROM brand_step;