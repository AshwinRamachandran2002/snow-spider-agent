-- Task: Retrieve the object id and the confidence value from the cropHintsAnnotation data where the confidence is greater than 0.5.
SELECT t."object_id", f.value:"confidence"::FLOAT AS "confidence"
FROM THE_MET.THE_MET.VISION_API_DATA t,
LATERAL FLATTEN(input => t."cropHintsAnnotation":cropHints) f
WHERE f.value:"confidence"::FLOAT > 0.5;