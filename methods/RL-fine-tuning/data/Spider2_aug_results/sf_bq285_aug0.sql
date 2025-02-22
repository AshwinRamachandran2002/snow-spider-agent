-- Task: Find the zip code(s) in Florida that have the highest number of distinct bank institutions, based on unique FDIC certificate numbers.
SELECT "zip_code"
FROM (
  SELECT "zip_code", COUNT(DISTINCT "fdic_certificate_number") AS "institution_count"
  FROM "FDA"."FDIC_BANKS"."LOCATIONS"
  WHERE "state_name" = 'Florida'
  GROUP BY "zip_code"
) AS zip_counts
WHERE "institution_count" = (
  SELECT MAX("institution_count") FROM (
    SELECT "zip_code", COUNT(DISTINCT "fdic_certificate_number") AS "institution_count"
    FROM "FDA"."FDIC_BANKS"."LOCATIONS"
    WHERE "state_name" = 'Florida'
    GROUP BY "zip_code"
  ) AS sub
);