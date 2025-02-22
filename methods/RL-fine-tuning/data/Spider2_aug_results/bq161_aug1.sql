-- Task: For each pancreatic adenocarcinoma (PAAD) patient, determine whether they have a mutation in the KRAS gene that has passed quality filters.

WITH
barcodes AS (
   SELECT bcr_patient_barcode AS ParticipantBarcode
   FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
   WHERE acronym = 'PAAD'
),
table1 AS (
   SELECT
      t1.ParticipantBarcode,
      IF(t2.ParticipantBarcode IS NULL, 'NO', 'YES') AS HasKRASMutation
   FROM
      barcodes AS t1
   LEFT JOIN (
      SELECT
         ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE Study = 'PAAD'
        AND Hugo_Symbol = 'KRAS'
        AND FILTER = 'PASS'
      GROUP BY ParticipantBarcode
   ) AS t2
   ON t1.ParticipantBarcode = t2.ParticipantBarcode
)

SELECT * FROM table1;