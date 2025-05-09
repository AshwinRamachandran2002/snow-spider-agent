WITH License_Counts AS (
  SELECT
    pv."System",
    f.value::STRING AS "License",
    COUNT(DISTINCT pv."Purl") AS "Package_Count"
  FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv,
       LATERAL FLATTEN(input => PARSE_JSON(pv."Licenses")) f
  GROUP BY pv."System", "License"
)
SELECT
  "System",
  "License" AS "Most_Frequently_Used_License"
FROM (
  SELECT
    lc.*,
    ROW_NUMBER() OVER (PARTITION BY lc."System" ORDER BY lc."Package_Count" DESC NULLS LAST) AS "RowNum"
  FROM License_Counts lc
) t
WHERE "RowNum" = 1
ORDER BY "System";