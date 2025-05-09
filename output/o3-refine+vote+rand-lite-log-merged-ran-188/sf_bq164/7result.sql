-- Consolidate Level-1‒4 + auxiliary spatial-transcriptomics files
-- for run ID “HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test”
WITH consolidated AS (
    /* ---------- Level-1 FASTQ ---------- */
    SELECT  "Filename",
            "HTAN_Parent_Biospecimen_ID",
            "Component",
            "File_Format",
            "entityId",
            "Run_ID"
    FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
    WHERE   "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ---------- Level-2 BAM ---------- */
    SELECT  "Filename",
            "HTAN_Parent_Biospecimen_ID",
            "Component",
            "File_Format",
            "entityId",
            "Run_ID"
    FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
    WHERE   "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ---------- Level-3 TSV / GZIP / JSON ---------- */
    SELECT  "Filename",
            "HTAN_Parent_Biospecimen_ID",
            "Component",
            "File_Format",
            "entityId",
            "Run_ID"
    FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
    WHERE   "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ---------- Level-4 HDF5, etc. ---------- */
    SELECT  "Filename",
            "HTAN_Parent_Biospecimen_ID",
            "Component",
            "File_Format",
            "entityId",
            "Run_ID"
    FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
    WHERE   "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'

    UNION ALL
    /* ---------- Auxiliary side-car files ---------- */
    SELECT  "Filename",
            "HTAN_Parent_Biospecimen_ID",
            "Component",
            "File_Format",
            "entityId",
            "Run_ID"
    FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
    WHERE   "Run_ID" ILIKE '%HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test%'
)
SELECT DISTINCT
       "Filename",
       "HTAN_Parent_Biospecimen_ID",
       "Component",
       "File_Format",
       "entityId",
       "Run_ID"
FROM   consolidated
ORDER  BY "Component",
          "Filename";