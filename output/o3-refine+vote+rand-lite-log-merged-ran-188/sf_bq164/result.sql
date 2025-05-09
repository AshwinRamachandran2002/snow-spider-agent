/* Consolidate spatial-transcriptomics (10x Visium) metadata from Levels 1-4
   and Auxiliary tables for the specific run ID */
WITH combined AS (
    ------------------------------------------------------------------
    --  Level-1 fastq files
    ------------------------------------------------------------------
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
    WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

    UNION ALL
    ------------------------------------------------------------------
    --  Level-2 BAM files
    ------------------------------------------------------------------
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
    WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

    UNION ALL
    ------------------------------------------------------------------
    --  Level-3 matrix / feature files
    ------------------------------------------------------------------
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
    WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

    UNION ALL
    ------------------------------------------------------------------
    --  Level-4 analysed objects
    ------------------------------------------------------------------
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
    WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

    UNION ALL
    ------------------------------------------------------------------
    --  Auxiliary image / JSON helper files
    ------------------------------------------------------------------
    SELECT
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
    WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
)
SELECT
    "Filename",
    "HTAN_Parent_Biospecimen_ID" AS "HTAN Parent Biospecimen ID",
    "Component",
    "File_Format"              AS "File Format",
    "entityId"                 AS "Entity ID",
    "Run_ID"                   AS "Run ID"
FROM combined
ORDER BY "Component", "File_Format", "Filename";