WITH patients_a AS (        -- patients whose family name starts with "A"
  SELECT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE LOWER(n.family) LIKE 'a%'                      -- last name begins with A
    AND (p.active IS TRUE OR p.active IS NULL)         -- keep “living/active” (NULL ≡ active here)
),
one_condition_patients AS (  -- keep only pts that have EXACTLY one distinct condition
  SELECT c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  WHERE c.subject.patientId IN (SELECT patient_id FROM patients_a)
  GROUP BY patient_id
  HAVING COUNT(DISTINCT c.code.text) = 1
),
cond_per_patient AS (        -- each patient’s lone condition
  SELECT
    c.subject.patientId                                                           AS patient_id,
    (SELECT cd.code
     FROM UNNEST(IFNULL(c.code.coding, [])) cd LIMIT 1)                           AS condition_code,
    c.code.text                                                                   AS condition_text
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  WHERE c.subject.patientId IN (SELECT patient_id FROM one_condition_patients)
),
active_med_counts AS (       -- count of different ACTIVE medications per patient
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT (
        SELECT cd.code
        FROM UNNEST(IFNULL(mr.medication.codeableConcept.coding, [])) cd LIMIT 1)
    ) AS med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE LOWER(mr.status) = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM one_condition_patients)
  GROUP BY patient_id
)
SELECT
  cp.condition_code            AS code,
  cp.condition_text            AS condition,
  MAX(IFNULL(amc.med_cnt,0))   AS highest_active_med_count
FROM cond_per_patient AS cp
LEFT JOIN active_med_counts AS amc
ON  cp.patient_id = amc.patient_id
GROUP BY code, condition
ORDER BY highest_active_med_count DESC
LIMIT 8;