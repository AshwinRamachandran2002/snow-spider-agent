-- Task: What is the average overall association score for psoriasis?

SELECT
  AVG(associations.score) AS avg_score
FROM
  `open-targets-prod.platform.associationByOverallDirect` AS associations
JOIN
  `open-targets-prod.platform.diseases` AS diseases
ON
  associations.diseaseId = diseases.id
WHERE
  diseases.name = 'psoriasis'