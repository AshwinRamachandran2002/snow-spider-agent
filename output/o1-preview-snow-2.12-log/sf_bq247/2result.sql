SELECT p."family_id", a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
  ON p."publication_number" = a."publication_number"
WHERE p."family_id" IN (
  SELECT "family_id"
  FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
  WHERE "family_id" <> '-1'
  GROUP BY "family_id"
  ORDER BY COUNT(*) DESC NULLS LAST
  LIMIT 6
)
AND a."abstract" IS NOT NULL AND a."abstract" <> '';