WITH counts AS (
  SELECT
    pv."System",
    CAST(l.value AS STRING) AS "License",
    COUNT(*) AS "package_count"
  FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" AS pv,
       LATERAL FLATTEN(input => pv."Licenses") l
  GROUP BY pv."System", "License"
)
SELECT "System", "License" AS "Most_Frequently_Used_License"
FROM (
  SELECT
    "System",
    "License",
    "package_count",
    ROW_NUMBER() OVER (
      PARTITION BY "System"
      ORDER BY "package_count" DESC NULLS LAST
    ) AS rn
  FROM counts
) sub
WHERE rn = 1;