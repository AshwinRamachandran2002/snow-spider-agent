-- Task: Find the ids of molecules whose name, trade names, or synonyms contain 'Keytruda', 'Vioxx', 'Premarin', or 'Humira'.
WITH matched_ids AS (
  SELECT t."id"
  FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE t
  WHERE t."name" ILIKE '%Keytruda%' OR
        t."name" ILIKE '%Vioxx%' OR
        t."name" ILIKE '%Premarin%' OR
        t."name" ILIKE '%Humira%'
  UNION
  SELECT t."id"
  FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE t,
       LATERAL FLATTEN(input => t."tradeNames") f1
  WHERE f1.value::STRING ILIKE '%Keytruda%' OR
        f1.value::STRING ILIKE '%Vioxx%' OR
        f1.value::STRING ILIKE '%Premarin%' OR
        f1.value::STRING ILIKE '%Humira%'
  UNION
  SELECT t."id"
  FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE t,
       LATERAL FLATTEN(input => t."synonyms") f2
  WHERE f2.value::STRING ILIKE '%Keytruda%' OR
        f2.value::STRING ILIKE '%Vioxx%' OR
        f2.value::STRING ILIKE '%Premarin%' OR
        f2.value::STRING ILIKE '%Humira%'
)
SELECT DISTINCT * FROM matched_ids;