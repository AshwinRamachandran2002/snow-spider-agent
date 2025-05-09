-- number of living patients who have diabetes or hypertension
-- and are taking at least seven distinct active medications
WITH alive_patients AS (
  SELECT
    id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient`
  WHERE
    deceased.dateTime IS NULL
    AND (deceased.boolean IS NULL OR deceased.boolean = FALSE)
), condition_patients AS (
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.condition` AS c
    LEFT JOIN UNNEST(c.code.coding) AS cd
  WHERE
    LOWER(COALESCE(c.code.text, '')) LIKE '%diabet%'
    OR LOWER(COALESCE(c.code.text, '')) LIKE '%hypertens%'
    OR LOWER(COALESCE(cd.display ,'')) LIKE '%diabet%'
    OR LOWER(COALESCE(cd.display ,'')) LIKE '%hypertens%'
), active_med_counts AS (
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT
          COALESCE(
            (SELECT coding.code
             FROM UNNEST(mr.medication.codeableConcept.coding) AS coding
             WHERE coding.code IS NOT NULL
             LIMIT 1),
            mr.medication.codeableConcept.text)
         ) AS active_med_count
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE
    mr.status = 'active'
    AND mr.subject.patientId IS NOT NULL
  GROUP BY
    patient_id
  HAVING
    active_med_count >= 7
)
SELECT
  COUNT(*) AS num_patients
FROM
  alive_patients AS a
  INNER JOIN condition_patients AS d
    ON a.patient_id = d.patient_id
  INNER JOIN active_med_counts AS m
    ON a.patient_id = m.patient_id;