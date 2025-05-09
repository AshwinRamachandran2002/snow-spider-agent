/*----------------------------------------------------------
  Breast-cancer (topo = 0401)  +  Adenocarcinoma (morph = 3111)
  Copy-number classes per cytogenetic band
  – Amplification ( > 1 extra copy)
  – Gain           ( +1 copy )
  – Loss           ( –1 copy )
  – HomozygousDel  ( –2 copies)
----------------------------------------------------------*/
WITH cohort_clones AS (            -- all unique clones in the cohort
    SELECT DISTINCT
           CONCAT(cv."RefNo",'-',cv."CaseNo",'-',cv."InvNo",'-',cv."Clone") AS clone_id
    FROM   MITELMAN.PROD.CYTOCONVERTED cv
    JOIN   MITELMAN.PROD.CYTOGEN       c
           ON  c."RefNo"  = cv."RefNo"
           AND c."CaseNo" = cv."CaseNo"
    WHERE  c."Morph" = '3111'          -- adenocarcinoma
       OR  c."Topo"  = '0401'          -- breast
),

band_events AS (                    -- map segments to hg38 bands
    SELECT
        b."chromosome",
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        /* harmonise CytoConverter labels to the four requested classes */
        CASE
            WHEN LOWER(cv."Type") IN ('amp','amplification','gain>1','gain2','gain3','gain4')   THEN 'Amplification'
            WHEN LOWER(cv."Type") IN ('gain','+1','dup','duplication')                          THEN 'Gain'
            WHEN LOWER(cv."Type") IN ('loss','-1','del','deletion')                             THEN 'Loss'
            WHEN LOWER(cv."Type") IN ('homdel','homozygous deletion','loss2','loss>1')          THEN 'HomozygousDel'
            ELSE cv."Type"       -- fall-back (kept for completeness)
        END                                                                 AS EventClass,
        CONCAT(cv."RefNo",'-',cv."CaseNo",'-',cv."InvNo",'-',cv."Clone")    AS clone_id
    FROM   MITELMAN.PROD.CYTOCONVERTED cv
    JOIN   MITELMAN.PROD.CYTOGEN       c
           ON  c."RefNo"  = cv."RefNo"
           AND c."CaseNo" = cv."CaseNo"
    JOIN   MITELMAN.PROD.CYTOBANDS_HG38 b
           ON  cv."Chr"   = b."chromosome"
          AND cv."Start" <= b."hg38_stop"
          AND cv."End"   >= b."hg38_start"
    WHERE  c."Morph" = '3111'
       OR  c."Topo"  = '0401'
)

SELECT
    be."chromosome",
    be."cytoband_name",
    be."hg38_start",
    be."hg38_stop",
    be.EventClass                                AS "Event_class",
    COUNT(DISTINCT be.clone_id)                  AS "N_clones",
    ROUND( 100.0 * COUNT(DISTINCT be.clone_id)
           / (SELECT COUNT(*) FROM cohort_clones)
         , 2)                                    AS "Frequency_%"
FROM   band_events be
WHERE  be.EventClass IN ('Amplification','Gain','Loss','HomozygousDel')
GROUP  BY be."chromosome",
          be."cytoband_name",
          be."hg38_start",
          be."hg38_stop",
          be.EventClass
ORDER  BY
       CASE WHEN be."chromosome" = 'chrX' THEN 23
            WHEN be."chromosome" = 'chrY' THEN 24
            ELSE TO_NUMBER(REPLACE(be."chromosome",'chr',''))
       END,
       be."hg38_start",
       be."hg38_stop";