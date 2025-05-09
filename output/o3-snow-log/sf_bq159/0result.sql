WITH
/*---------------------------- 1.  BRCA patients with known histology ----------------------------*/
brca_clin AS (
    SELECT
        "bcr_patient_barcode"  AS participant,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
),
/*---------------------------- 2.  Reliable CDH1-mutation carriers ------------------------------*/
cdh1_mut AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study"       = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
        AND "FILTER"   = 'PASS'
),
/*---------------------------- 3.  Mutation-status per patient ----------------------------------*/
patient_status AS (
    SELECT
        c.participant,
        c."histological_type",
        /* 1 = mutated, 0 = wild-type */
        CASE WHEN m.participant IS NOT NULL THEN 1 ELSE 0 END AS mutated
    FROM brca_clin c
    LEFT JOIN cdh1_mut m
           ON c.participant = m.participant
),
/* keep only histological types with >10 total patients */
histology_totals AS (
    SELECT "histological_type", COUNT(*) AS total_hist
    FROM patient_status
    GROUP BY "histological_type"
    HAVING COUNT(*) > 10
),
filtered_patients AS (
    SELECT p.*
    FROM patient_status p
    JOIN histology_totals h
      ON p."histological_type" = h."histological_type"
),
/*---------------------------- 4.  Contingency table --------------------------------------------*/
contingency0 AS (
    SELECT
        "histological_type",
        mutated,
        COUNT(*) AS obs
    FROM filtered_patients
    GROUP BY "histological_type", mutated
),
/* drop mutation-status columns whose overall total ≤10        */
col_totals AS (
    SELECT mutated, SUM(obs) AS col_total
    FROM contingency0
    GROUP BY mutated
    HAVING SUM(obs) > 10
),
contingency AS (
    SELECT c.*
    FROM contingency0 c
    JOIN col_totals ct USING (mutated)
),
/*---------------------------- 5.  Marginal & grand totals --------------------------------------*/
row_totals   AS (SELECT "histological_type", SUM(obs) AS row_total FROM contingency GROUP BY "histological_type"),
grand_total  AS (SELECT SUM(obs) AS grand_total FROM contingency),
/*---------------------------- 6.  Chi-square components ----------------------------------------*/
chi_components AS (
    SELECT
        c."histological_type",
        c.mutated,
        c.obs,
        rt.row_total,
        ct.col_total,
        g.grand_total,
        POWER( c.obs - (rt.row_total * ct.col_total / g.grand_total), 2 )
        / (rt.row_total * ct.col_total / g.grand_total)                              AS chi_component
    FROM contingency      c
    JOIN row_totals       rt ON rt."histological_type" = c."histological_type"
    JOIN col_totals       ct USING (mutated)
    JOIN grand_total      g
)
/*---------------------------- 7.  Chi-square statistic -----------------------------------------*/
SELECT
    ROUND( SUM(chi_component), 4 ) AS chi_square_value
FROM chi_components;