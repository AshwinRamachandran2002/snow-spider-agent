WITH
  brca_clin AS (
    SELECT
      "bcr_patient_barcode"        AS "patient_id",
      "histological_type"          AS "histological_type"
    FROM
      PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE
      "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
  ),

  cdh1_mutated_patients AS (
    SELECT DISTINCT
      "ParticipantBarcode" AS "patient_id"
    FROM
      PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE
      "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
  )

SELECT
  bc."histological_type",
  COUNT(DISTINCT bc."patient_id")                                         AS "total_patients",
  COUNT(DISTINCT CASE WHEN mp."patient_id" IS NOT NULL THEN bc."patient_id" END) AS "mutated_patients",
  ROUND(
        COUNT(DISTINCT CASE WHEN mp."patient_id" IS NOT NULL THEN bc."patient_id" END)
        * 100.0
        / COUNT(DISTINCT bc."patient_id"),
        4
  )                                                                       AS "mutation_percentage"
FROM
  brca_clin bc
LEFT JOIN
  cdh1_mutated_patients mp
ON
  bc."patient_id" = mp."patient_id"
GROUP BY
  bc."histological_type"
ORDER BY
  "mutation_percentage" DESC NULLS LAST,
  bc."histological_type"
LIMIT 5;