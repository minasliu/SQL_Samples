/*****************************************************************************/
/*     File Name     : plan_working.sql                                     */
/*     Description   : Pulls Working plan for PlanJust File to dev plan     */
/*     Input tables  : 	keycomp_desc_cd_v                                    */
/*			plan_calendar_cd_v                                   */
/*			quarter_d_v                                          */
/*			wrk_plan_plat_desc_drv_v                             */
/*     Output file   :  /home/minal/HardDrives/Plan/plan_working-config.csv  */
/*     			/home/minal/HardDrives/Plan/plan_working-sysflex.csv */
/*****************************************************************************/

SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET VERIFY ON;
SET HEADING OFF;


SPOOL /home/minal/HardDrives/Plan/plan_working-config.csv;
PROMPT Working KC Configured Plan,,,,,,,
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM') ||',,,,,,,'
FROM dual;

CREATE TABLE temp_table_ML AS
SELECT k.keycomp_desc kc_desc,
	q.qtr_fiscal_year_qtr fisc_qtr,
	sum(w.kc_desc_cfg_plan_qty) kc_config
FROM	keycomp_desc_cd_v k,
	wrk_plan_plat_desc_drv_v w,
	quarter_d_v q
WHERE k.keycomp_desc_pk=w.keycomp_desc_pk
AND	q.qtr_pk=w.qtr_pk
AND   k.kcd_kc_type IN ('STORAGE_HD') 
GROUP BY k.keycomp_desc,
	q.qtr_fiscal_year_qtr;
	
CREATE TABLE temp_table_ML2 AS
SELECT 	kc_desc,
	decode(fisc_qtr, '2002Q4',kc_config,0) FY02Q4,
	decode(fisc_qtr, '2003Q1',kc_config,0) FY03Q1,
	decode(fisc_qtr, '2003Q2',kc_config,0) FY03Q2,
	decode(fisc_qtr, '2003Q3',kc_config,0) FY03Q3,
	decode(fisc_qtr, '2003Q4',kc_config,0) FY03Q4,
	decode(fisc_qtr, '2004Q1',kc_config,0) FY04Q1
FROM temp_table_ML
GROUP BY kc_desc,
	fisc_qtr,
	kc_config;

PROMPT kc_desc,FY02Q4,FY03Q1,FY03Q2,FY03Q3,FY03Q4,FY04Q1,
SELECT 	kc_desc ||','||
	sum(FY02Q4) ||','||
	sum(FY03Q1) ||','||
	sum(FY03Q2) ||','||
	sum(FY03Q3) ||','||
	sum(FY03Q4) ||','||
	sum(FY04Q1) ||','
FROM temp_table_ML2
GROUP BY kc_desc
ORDER BY kc_desc;

SPOOL OFF;


SPOOL /home/minal/HardDrives/Plan/plan_working-sysflex.csv;
PROMPT Working KC System Flex Plan,,,,,,,
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM') ||',,,,,,,'
FROM dual;
PROMPT Working Plan last updated,,,,,,,
SELECT TO_CHAR(MAX(wrk_plan_last_upd_date),'Mon DD YYYY HH:MIAM') ||',,,,,,,'
FROM wrk_plan_plat_kc_drv_mx_v;

CREATE TABLE kc_temp_table_ML AS
SELECT  keycomp_desc kc_desc, 
        q.qtr_fiscal_year_qtr fisc_qtr,
        pkcd.platform_pk platform_pk,
        sum(pkcd.plat_to_kc_drv_mix_qty) mix,
        '          ' plat_flex,
        '          ' sys_flex
FROM    wrk_plan_plat_kc_drv_mx_v pkcd,
        kc_drv_to_kc_desc_brg_v kd, 
        keycomp_desc_cd_v kc,
        quarter_d_v q
WHERE   q.qtr_pk = pkcd.qtr_pk
AND	pkcd.keycomp_driver_pk = kd.keycomp_driver_pk
AND	kd.keycomp_desc_pk = kc.keycomp_desc_pk
AND     kc.kcd_kc_type = 'STORAGE_HD'  
GROUP BY kc.keycomp_desc,
	pkcd.platform_pk,
	q.qtr_fiscal_year_qtr
ORDER BY kc.keycomp_desc,
	pkcd.platform_pk,
	q.qtr_fiscal_year_qtr;
         
CREATE TABLE plat_temp_table_ML AS
SELECT	q.qtr_fiscal_year_qtr fisc_qtr,
	p.platform_pk platform_pk,
	sum(p.plat_flex_qty) plat_flex
FROM    wrk_plan_platform_v p, 
        quarter_d_v q
WHERE   q.qtr_pk = p.qtr_pk 
GROUP BY q.qtr_fiscal_year_qtr,
	p.platform_pk
ORDER BY p.platform_pk,
	q.qtr_fiscal_year_qtr;
        
UPDATE kc_temp_table_ML
SET	plat_flex=(SELECT sum(plat_flex)
			FROM plat_temp_table_ML
			WHERE 	plat_temp_table_ML.platform_pk=kc_temp_table_ML.platform_pk
			AND 	plat_temp_table_ML.fisc_qtr=kc_temp_table_ML.fisc_qtr);

UPDATE kc_temp_table_ML
SET	sys_flex=round((plat_flex * mix),0);
	
DROP TABLE temp_table_ML;
CREATE TABLE temp_table_ML AS
SELECT 	kc_desc,
	decode(fisc_qtr, '2002Q4',sys_flex,0) FY02Q4,
	decode(fisc_qtr, '2003Q1',sys_flex,0) FY03Q1,
	decode(fisc_qtr, '2003Q2',sys_flex,0) FY03Q2,
	decode(fisc_qtr, '2003Q3',sys_flex,0) FY03Q3,
	decode(fisc_qtr, '2003Q4',sys_flex,0) FY03Q4,
	decode(fisc_qtr, '2004Q1',sys_flex,0) FY04Q1
FROM kc_temp_table_ML
GROUP BY kc_desc,
	fisc_qtr,
	sys_flex;

PROMPT kc_desc,FY02Q4,FY03Q1,FY03Q2,FY03Q3,FY03Q4,FY04Q1,
SELECT 	kc_desc ||','||
	sum(FY02Q4) ||','||
	sum(FY03Q1) ||','||
	sum(FY03Q2) ||','||
	sum(FY03Q3) ||','||
	sum(FY03Q4) ||','||
	sum(FY04Q1) ||','
FROM temp_table_ML
GROUP BY kc_desc
ORDER BY kc_desc;

SPOOL OFF;

DROP TABLE temp_table_ML;
DROP TABLE temp_table_ML2;
DROP TABLE plat_temp_table_ML;
DROP TABLE kc_temp_table_ML;

EXIT;

