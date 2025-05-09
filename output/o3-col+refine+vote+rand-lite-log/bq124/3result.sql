WITH dx AS (  -- patients diagnosed with Diabetes OR Hypertension
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cc
  WHERE LOWER(cc.display) LIKE '%diabetes%'
     OR LOWER(cc.display) LIKE '%hypertension%'
),
deceased AS (  -- patients recorded as deceased
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cc
  WHERE LOWER(cc.display) LIKE '%death%'
     OR LOWER(cc.display) LIKE '%dead%'
     OR LOWER(cc.display) LIKE '%deceased%'
),
polypharm AS (  -- patients with ≥7 distinct active medications
  SELECT
    mr.subject.patientId           AS patient_id,
    COUNT(DISTINCT mrc.code)       AS active_rx_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mrc
  WHERE mr.status = 'active'
  GROUP BY patient_id
  HAVING active_rx_cnt >= 7
)

SELECT
  COUNT(DISTINCT patient_id) AS alive_diab_or_htn_polypharm_cnt
FROM dx
JOIN polypharm USING (patient_id)
WHERE patient_id NOT IN (SELECT patient_id FROM deceased);