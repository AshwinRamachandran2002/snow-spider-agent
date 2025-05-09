-- count of living patients diagnosed with diabetes OR hypertension
-- who currently have at least 7 distinct active medication requests
WITH alive_patients AS (
  SELECT
    id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient`
  WHERE
    deceased IS NULL                               -- no deceased struct at all
    OR deceased.dateTime IS NULL                   -- or deceased dateTime not recorded
),

dx_patients AS (      -- patients with diabetes OR hypertension
  SELECT DISTINCT
    subject.patientId AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.condition` c
    LEFT JOIN UNNEST(c.code.coding) AS cd          -- explode the codings
  WHERE
    subject.patientId IS NOT NULL
    AND (
          LOWER(c.code.text)        LIKE '%diabet%'    OR
          LOWER(c.code.text)        LIKE '%hypertens%' OR
          LOWER(cd.display)         LIKE '%diabet%'    OR
          LOWER(cd.display)         LIKE '%hypertens%' OR
          LOWER(cd.code)            LIKE '%diabet%'    OR
          LOWER(cd.code)            LIKE '%hypertens%'
        )
),

med_patients AS (     -- patients with >=7 distinct active meds
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT med.code)        AS distinct_active_meds
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` mr,
    UNNEST(mr.medication.codeableConcept.coding) AS med   -- explode medication codings
  WHERE
    mr.status = 'active'
    AND mr.subject.patientId IS NOT NULL
    AND med.code IS NOT NULL
  GROUP BY
    mr.subject.patientId
  HAVING
    COUNT(DISTINCT med.code) >= 7
),

eligible_patients AS (
  SELECT
    a.patient_id
  FROM
    alive_patients   AS a
    JOIN dx_patients  AS d USING (patient_id)
    JOIN med_patients AS m USING (patient_id)
)

SELECT
  COUNT(*) AS alive_dx_active_med_ge7
FROM
  eligible_patients;