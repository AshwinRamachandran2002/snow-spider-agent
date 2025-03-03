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