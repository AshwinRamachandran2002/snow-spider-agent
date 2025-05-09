/*-----------------------------------------------------------
  Chi–square test of association between CDH1-mutation status
  (Mutated vs WildType) and histological subtype in TCGA-BRCA
  patients. 
  – uses only patients with a known histological type
  – keeps only histological types whose marginal total > 10
  – keeps only reliable mutation calls (FILTER = 'PASS')
-----------------------------------------------------------*/
WITH
/* 1.  BRCA patients carrying a reliable CDH1 mutation --------*/
mutation_flag AS (
    SELECT DISTINCT
           "ParticipantBarcode"                     AS "pb"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"          = 'BRCA'
      AND  "Hugo_Symbol"    = 'CDH1'
      AND  "FILTER"         = 'PASS'
),

/* 2.  Clinical BRCA patients with a known histology ----------*/
brca_clin AS (
    SELECT
           "bcr_patient_barcode"                    AS "pb",
           "histological_type"                      AS "histology"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE  "acronym"          = 'BRCA'
      AND  "histological_type" IS NOT NULL
),

/* 3.  Attach mutation status (Mutated / WildType) ------------*/
patient_status AS (
    SELECT
           c."histology",
           CASE WHEN m."pb" IS NOT NULL THEN 'Mutated'
                                            ELSE 'WildType' END  AS "mut_status"
    FROM   brca_clin           c
    LEFT  JOIN mutation_flag   m
           ON m."pb" = c."pb"
),

/* 4.  Keep histologies with >10 total cases ------------------*/
eligible_hist AS (
    SELECT  "histology"
    FROM    patient_status
    GROUP BY "histology"
    HAVING   COUNT(*) > 10
),

/* 5.  Observed cell counts (contingency table) ---------------*/
obs AS (
    SELECT
           ps."histology",
           ps."mut_status",
           COUNT(*)                                 AS "obs_n"
    FROM   patient_status  ps
    JOIN   eligible_hist   eh
           ON eh."histology" = ps."histology"
    GROUP  BY ps."histology",
             ps."mut_status"
),

/* 6.  Row totals, column totals, grand total -----------------*/
row_tot AS (
    SELECT "histology",
           SUM("obs_n")    AS "row_total"
    FROM   obs
    GROUP  BY "histology"
),
col_tot AS (
    SELECT "mut_status",
           SUM("obs_n")    AS "col_total"
    FROM   obs
    GROUP  BY "mut_status"
),
grand_tot AS (
    SELECT SUM("obs_n")    AS "grand_total"
    FROM   obs
),

/* 7.  Expected counts & chi-square contributions -------------*/
chi_parts AS (
    SELECT
           o."histology",
           o."mut_status",
           o."obs_n",
           (rt."row_total" * ct."col_total") / gt."grand_total"      AS "exp_n",
           POWER(o."obs_n" - (rt."row_total" * ct."col_total") / gt."grand_total", 2)
           /
           ((rt."row_total" * ct."col_total") / gt."grand_total")    AS "chi_component"
    FROM   obs         o
    JOIN   row_tot     rt  ON rt."histology"   = o."histology"
    JOIN   col_tot     ct  ON ct."mut_status"  = o."mut_status"
    JOIN   grand_tot   gt
)

/* 8.  Final chi-square statistic -----------------------------*/
SELECT 
       ROUND(SUM("chi_component"), 4) AS "chi_square_value"
FROM   chi_parts;