-- number of living patients with Dx of Diabetes OR Hypertension and
-- at least 7 different active medications
WITH alive_patients AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE (deceased.dateTime IS NULL)
        AND (deceased.boolean IS NULL OR deceased.boolean = FALSE)
), 

dx_patients AS (   -- patients diagnosed with Diabetes or Hypertension
  -- match on code text
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE subject.patientId IS NOT NULL
    AND (
          LOWER(code.text) LIKE '%diabetes%'      OR
          LOWER(code.text) LIKE '%hypertension%' 
        )

  UNION DISTINCT          -- match on any coding display / code
  SELECT DISTINCT subject.patientId
  FROM `bigquery-public-data.fhir_synthea.condition`,
       UNNEST(code.coding) AS c
  WHERE subject.patientId IS NOT NULL
    AND (
          LOWER(c.display) LIKE '%diabetes%'      OR
          LOWER(c.display) LIKE '%hypertension%'  OR
          c.code IN ('44054006',  -- Diabetes mellitus
                     '38341003')  -- Hypertensive disorder, systemic arterial (Hypertension)
        )
), 

med_counts AS (          -- number of distinct active meds per patient
  SELECT
      mr.subject.patientId                                    AS patient_id,
      COUNT(DISTINCT COALESCE(cc.code,
                              LOWER(mr.medication.codeableConcept.text))) AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  LEFT JOIN UNNEST(mr.medication.codeableConcept.coding) AS cc
  WHERE mr.status = 'active'
        AND mr.subject.patientId IS NOT NULL
  GROUP BY patient_id
  HAVING active_med_cnt >= 7
)

SELECT COUNT(*) AS alive_dx_7plus_active_meds
FROM alive_patients   a
JOIN dx_patients      d ON a.patient_id = d.patient_id
JOIN med_counts       m ON a.patient_id = m.patient_id;