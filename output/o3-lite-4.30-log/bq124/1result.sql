SELECT
  'alive_with_dx_and_7plus_active_meds' AS criteria,
  COUNT(*)                               AS count
FROM (
  WITH alive AS (
    SELECT id AS patient_id
    FROM `bigquery-public-data.fhir_synthea.patient`
    WHERE deceased.dateTime IS NULL
  ),
  dx AS (
    SELECT DISTINCT c.subject.patientId AS patient_id
    FROM `bigquery-public-data.fhir_synthea.condition` AS c
    LEFT JOIN UNNEST(c.code.coding) AS cc
    WHERE
          LOWER(IFNULL(c.code.text,  '')) LIKE '%diabet%'
       OR LOWER(IFNULL(c.code.text,  '')) LIKE '%hyperten%'
       OR LOWER(IFNULL(cc.display ,   '')) LIKE '%diabet%'
       OR LOWER(IFNULL(cc.display ,   '')) LIKE '%hyperten%'
  ),
  meds AS (
    SELECT mr.subject.patientId AS patient_id
    FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
    CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
    WHERE mr.status = 'active'
    GROUP BY patient_id
    HAVING COUNT(DISTINCT mc.code) >= 7
  )
  SELECT a.patient_id
  FROM alive a
  JOIN dx   USING (patient_id)
  JOIN meds USING (patient_id)
);