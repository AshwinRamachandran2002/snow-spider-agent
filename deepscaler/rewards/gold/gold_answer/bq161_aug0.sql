-- Task: Calculate the difference between the number of pancreatic adenocarcinoma (PAAD) patients from the clinical data who have mutations in both KRAS and TP53 genes (with mutations passing the 'PASS' quality filter), and those who have mutations in neither gene. Use `ParticipantBarcode` to join the clinical data (where `acronym` = 'PAAD') with the mutation data (where `Study` = 'PAAD', `Hugo_Symbol` = 'KRAS' or 'TP53', and `FILTER` = 'PASS').

WITH
barcodes AS (
   SELECT bcr_patient_barcode AS ParticipantBarcode
   FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
   WHERE acronym = 'PAAD'
),
table1 AS (
   SELECT
      t1.ParticipantBarcode,
      IF(t2.ParticipantBarcode IS NULL, 'NO', 'YES') AS data
   FROM
      barcodes AS t1
   LEFT JOIN (
      SELECT
         ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE Study = 'PAAD' AND Hugo_Symbol = 'KRAS' AND FILTER = 'PASS'
      GROUP BY ParticipantBarcode
   ) AS t2 ON t1.ParticipantBarcode = t2.ParticipantBarcode
),
table2 AS (
   SELECT
      t1.ParticipantBarcode,
      IF(t2.ParticipantBarcode IS NULL, 'NO', 'YES') AS data
   FROM
      barcodes AS t1
   LEFT JOIN (
      SELECT
         ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE Study = 'PAAD' AND Hugo_Symbol = 'TP53' AND FILTER = 'PASS'
      GROUP BY ParticipantBarcode
   ) AS t2 ON t1.ParticipantBarcode = t2.ParticipantBarcode
),
INFO AS (
   SELECT
      n1.data AS data1,
      n2.data AS data2,
      COUNT(*) AS Nij
   FROM
      table1 AS n1
   INNER JOIN
      table2 AS n2 ON n1.ParticipantBarcode = n2.ParticipantBarcode
   GROUP BY
      data1, data2
)
SELECT 
   (SELECT Nij FROM INFO WHERE data1 = "YES" AND data2 = "YES") -
   (SELECT Nij FROM INFO WHERE data1 = "NO" AND data2 = "NO")