WITH Patient_Expression AS
(
    SELECT "ParticipantBarcode", AVG(LOG(10, "normalized_count" +1)) AS "Avg_Log_Expression"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG' AND "Symbol" = 'IGF2' AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
Patient_Data AS
(
    SELECT pe."ParticipantBarcode", pe."Avg_Log_Expression", c."icd_o_3_histology"
    FROM Patient_Expression pe
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
    ON pe."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE c."icd_o_3_histology" IS NOT NULL 
      AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')
),
Group_Sizes AS
(
    SELECT "icd_o_3_histology", COUNT(*) AS "Group_Size"
    FROM Patient_Data
    GROUP BY "icd_o_3_histology"
    HAVING COUNT(*) > 1
),
Filtered_Patient_Data AS
(
    SELECT pd."ParticipantBarcode", pd."Avg_Log_Expression", pd."icd_o_3_histology"
    FROM Patient_Data pd
    JOIN Group_Sizes gs ON pd."icd_o_3_histology" = gs."icd_o_3_histology"
),
Ranked_Values AS
(
    SELECT
        fd."ParticipantBarcode", fd."Avg_Log_Expression", fd."icd_o_3_histology",
        RANK() OVER (ORDER BY fd."Avg_Log_Expression") AS "Rank"
    FROM Filtered_Patient_Data fd
),
Value_Ranks AS
(
    SELECT
        rv."Avg_Log_Expression",
        AVG(rv."Rank") AS "Avg_Rank"
    FROM Ranked_Values rv
    GROUP BY rv."Avg_Log_Expression"
),
Patient_Ranks AS
(
    SELECT rv."ParticipantBarcode", rv."Avg_Log_Expression", rv."icd_o_3_histology", vr."Avg_Rank"
    FROM Ranked_Values rv
    JOIN Value_Ranks vr ON rv."Avg_Log_Expression" = vr."Avg_Log_Expression"
),
Group_Sums AS
(
    SELECT pr."icd_o_3_histology", COUNT(*) AS n_i,
           SUM(pr."Avg_Rank") AS S_i
    FROM Patient_Ranks pr
    GROUP BY pr."icd_o_3_histology"
),
Overall_Sums AS
(
    SELECT
        SUM(gs.n_i) AS N,
        SUM(gs.S_i) AS Sum_S_i
    FROM Group_Sums gs
),
Compute_Numerator AS
(
    SELECT SUM((gs.S_i * gs.S_i) / gs.n_i) AS Numerator_Term
    FROM Group_Sums gs
),
Compute_Denominator AS
(
    SELECT SUM(POWER(pr."Avg_Rank",2)) AS Sum_Q_i
    FROM Patient_Ranks pr
),
H_Score AS
(
    SELECT
        (os.N -1) *
        (
            (cn.Numerator_Term - (os.Sum_S_i * os.Sum_S_i) / os.N)
            /
            (cd.Sum_Q_i - (os.Sum_S_i * os.Sum_S_i) / os.N)
        ) AS "Kruskal_Wallis_H_score"
    FROM Overall_Sums os, Compute_Numerator cn, Compute_Denominator cd
)

SELECT
    (SELECT COUNT(*) FROM Group_Sizes) AS "Total_Groups",
    (SELECT COUNT(*) FROM Patient_Ranks) AS "Total_Samples",
    (SELECT ROUND("Kruskal_Wallis_H_score", 4) FROM H_Score) AS "Kruskal_Wallis_H_score";