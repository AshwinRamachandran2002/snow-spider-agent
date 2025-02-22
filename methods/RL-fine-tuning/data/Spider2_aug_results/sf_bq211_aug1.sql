-- Task: List up to 100 family_ids that have more than one distinct application_number.
SELECT "family_id"
FROM PATENTS.PATENTS.PUBLICATIONS
GROUP BY "family_id"
HAVING COUNT(DISTINCT "application_number") > 1
LIMIT 100;