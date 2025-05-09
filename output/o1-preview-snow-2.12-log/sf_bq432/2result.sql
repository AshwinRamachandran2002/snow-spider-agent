SELECT
  "report_number",
  REPLACE(REPLACE("reactions", ', ', ','), '"""', '') AS "reactions",
  REPLACE("outcomes", ', ', ',') AS "outcomes",
  REPLACE("products_brand_name", ', ', ' -- ') AS "products_brand_name",
  REPLACE("products_industry_code", ', ', ' -- ') AS "products_industry_code",
  REPLACE("products_role", ', ', ' -- ') AS "products_role",
  REPLACE("products_industry_name", ', ', ' -- ') AS "products_industry_name",
  "date_created",
  "date_started",
  "consumer_gender",
  ROUND("consumer_age", 4) AS "consumer_age",
  "consumer_age_unit",
  ARRAY_SIZE(SPLIT(REPLACE("products_industry_code", ', ', ' -- '), ',')) AS "industry_code_length",
  ARRAY_SIZE(SPLIT(REPLACE("products_brand_name", ', ', ' -- '), ',')) AS "brand_name_length"
FROM
  "FDA"."FDA_FOOD"."FOOD_EVENTS"
WHERE
  "date_created" >= '2015-01-01' AND "date_created" < '2015-02-01';