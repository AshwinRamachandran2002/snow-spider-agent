/* chromosomal-band copy-number profile for breast cancer (Morph=3111)
   and adenocarcinoma (Topo=0401) cases                                   */

WITH cohort_cases AS (          -- all (RefNo,CaseNo) belonging to cohort
    SELECT DISTINCT RefNo, CaseNo
    FROM   `mitelman-db.prod.Cytogen`
    WHERE  Morph = '3111'        -- breast carcinoma
       OR  Topo  = '0401'        -- adenocarcinoma
),

band_events AS (                -- each copy-number segment ↔ cytoband overlap
    SELECT
        cb.chromosome,          -- e.g.  chr14
        cb.cytoband_name,       -- e.g.  14q32
        cb.hg38_start,
        cb.hg38_stop,
        cc.Type                 -- Amplification | Gain | Loss | HomozygousDeletion
    FROM   `mitelman-db.prod.CytoConverted`  AS cc
    JOIN   cohort_cases                        USING (RefNo, CaseNo)
    JOIN   `mitelman-db.prod.CytoBands_hg38`  AS cb
      ON  cb.chromosome = cc.Chr
     AND cc.Start < cb.hg38_stop              -- interval intersection
     AND cc.End   > cb.hg38_start
)

SELECT
    chromosome                                     AS Chr,
    cytoband_name                                  AS Band,
    COUNTIF(Type = 'Amplification')        AS n_amp,
    COUNTIF(Type = 'Gain')                 AS n_gain,
    COUNTIF(Type = 'Loss')                 AS n_loss,
    COUNTIF(Type = 'HomozygousDeletion')   AS n_homdel,
    CONCAT(FORMAT('%.2f', 100 * COUNTIF(Type = 'Amplification')      / COUNT(*)), '%')
                                                AS freq_amp,
    CONCAT(FORMAT('%.2f', 100 * COUNTIF(Type = 'Gain')               / COUNT(*)), '%')
                                                AS freq_gain,
    CONCAT(FORMAT('%.2f', 100 * COUNTIF(Type = 'Loss')               / COUNT(*)), '%')
                                                AS freq_loss,
    CONCAT(FORMAT('%.2f', 100 * COUNTIF(Type = 'HomozygousDeletion') / COUNT(*)), '%')
                                                AS freq_homdel
FROM   band_events
GROUP BY
        Chr,
        Band,
        hg38_start,
        hg38_stop
ORDER BY
    CASE                                       -- chromosome ordinal
        WHEN Chr = 'chrX' THEN  23
        WHEN Chr = 'chrY' THEN  24
        ELSE CAST(REGEXP_EXTRACT(Chr, r'chr(\d+)') AS INT64)
    END,
    hg38_start,
    hg38_stop;