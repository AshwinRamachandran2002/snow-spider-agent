SELECT
    CAST("report_number" AS STRING) AS "report_number",
    TRIM(REPLACE("reactions", '"""', '')) AS "reactions",
    TRIM("outcomes") AS "outcomes",
    CAST(REGEXP_REPLACE("products_brand_name", ', ', ' -- ') AS STRING) AS "products_brand_name",
    CAST(REGEXP_REPLACE("products_industry_code", ', ', ' -- ') AS STRING) AS "products_industry_code",
    CAST(REGEXP_REPLACE("products_role", ', ', ' -- ') AS STRING) AS "products_role",
    CAST(REGEXP_REPLACE("products_industry_name", ', ', ' -- ') AS STRING) AS "products_industry_name",
    "date_created",
    "date_started",
    CAST("consumer_gender" AS STRING) AS "consumer_gender",
    ROUND("consumer_age", 4) AS "consumer_age",
    CAST("consumer_age_unit" AS STRING) AS "consumer_age_unit",
    ARRAY_SIZE(SPLIT(REGEXP_REPLACE("products_industry_code", ', ', ' -- '), ' -- ')) AS "industry_code_length",
    ARRAY_SIZE(SPLIT(REGEXP_REPLACE("products_brand_name", ', ', ' -- '), ' -- ')) AS "brand_name_length"
FROM FDA.FDA_FOOD.FOOD_EVENTS
WHERE "date_created" BETWEEN '2015-01-01' AND '2015-01-31';