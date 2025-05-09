WITH
PAAD_Patients AS (
  SELECT DISTINCT "bcr_patient_barcode" AS "ParticipantBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
  WHERE "acronym" = 'PAAD'
),
KRAS_Mutations AS (
  SELECT DISTINCT "ParticipantBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  WHERE "Hugo_Symbol" = 'KRAS' AND "Study" = 'PAAD' AND "FILTER" = 'PASS'
),
TP53_Mutations AS (
  SELECT DISTINCT "ParticipantBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  WHERE "Hugo_Symbol" = 'TP53' AND "Study" = 'PAAD' AND "FILTER" = 'PASS'
),
Mutation_Status AS (
  SELECT p."ParticipantBarcode",
    CASE WHEN k."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "KRAS_Mut",
    CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "TP53_Mut"
  FROM PAAD_Patients p
  LEFT JOIN KRAS_Mutations k ON p."ParticipantBarcode" = k."ParticipantBarcode"
  LEFT JOIN TP53_Mutations t ON p."ParticipantBarcode" = t."ParticipantBarcode"
),
Counts AS (
  SELECT
    COUNT(*) AS "N",
    SUM(CASE WHEN "KRAS_Mut" = 1 AND "TP53_Mut" = 1 THEN 1 ELSE 0 END) AS "A",
    SUM(CASE WHEN "KRAS_Mut" = 1 AND "TP53_Mut" = 0 THEN 1 ELSE 0 END) AS "B",
    SUM(CASE WHEN "KRAS_Mut" = 0 AND "TP53_Mut" = 1 THEN 1 ELSE 0 END) AS "C",
    SUM(CASE WHEN "KRAS_Mut" = 0 AND "TP53_Mut" = 0 THEN 1 ELSE 0 END) AS "D"
  FROM Mutation_Status
),
Expected AS (
  SELECT
    C."N",
    C."A",
    C."B",
    C."C",
    C."D",
    (C."A" + C."B") AS "KRAS_Positive",
    (C."C" + C."D") AS "KRAS_Negative",
    (C."A" + C."C") AS "TP53_Positive",
    (C."B" + C."D") AS "TP53_Negative",
    ((C."A" + C."B") * (C."A" + C."C")) / CAST(C."N" AS FLOAT) AS "E_A",
    ((C."A" + C."B") * (C."B" + C."D")) / CAST(C."N" AS FLOAT) AS "E_B",
    ((C."C" + C."D") * (C."A" + C."C")) / CAST(C."N" AS FLOAT) AS "E_C",
    ((C."C" + C."D") * (C."B" + C."D")) / CAST(C."N" AS FLOAT) AS "E_D"
  FROM Counts C
),
ChiSquared AS (
  SELECT
    (("A" - "E_A") * ("A" - "E_A")) / "E_A" AS "Chi_A",
    (("B" - "E_B") * ("B" - "E_B")) / "E_B" AS "Chi_B",
    (("C" - "E_C") * ("C" - "E_C")) / "E_C" AS "Chi_C",
    (("D" - "E_D") * ("D" - "E_D")) / "E_D" AS "Chi_D",
    ((("A" - "E_A") * ("A" - "E_A")) / "E_A") + 
    ((("B" - "E_B") * ("B" - "E_B")) / "E_B") + 
    ((("C" - "E_C") * ("C" - "E_C")) / "E_C") + 
    ((("D" - "E_D") * ("D" - "E_D")) / "E_D") AS "chi_squared_value"
  FROM Expected
)
SELECT ROUND("chi_squared_value", 4) AS "chi-squared value"
FROM ChiSquared;