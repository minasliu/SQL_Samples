/*****************************************************************************/
/*     File Name     : plan_official.sql                                     */
/*     Description   : Pulls Official plan for PlanJust File to dev plan     */
/*     Input tables  : 	keycomp_desc_cd_v                                    */
/*			off_plan_kc_desc_v                                   */
/*			plan_calendar_cd_v                                   */
/*			quarter_d_v                                          */
/*			off_plan_plat_desc_drv_v                             */
/*     Output file   :  /home/minal/HardDrives/Plan/plan_official.csv        */
/*****************************************************************************/

SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET VERIFY ON;
SET HEADING OFF;


SPOOL /home/minal/HardDrives/Plan/plan_official.csv;
PROMPT Official KC Plan (Prior Plan)
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM') ||','
FROM dual;

CREATE TABLE temp_table_ML AS
SELECT	k.keycomp_desc kc_desc,
	q.qtr_fiscal_year_qtr fisc_qtr,
	0 kc_config,
	sum(o.kc_desc_ind_xopt_qty) kc_options,
	sum(o.kc_desc_flex_qty) kc_flex
FROM	keycomp_desc_cd_v k,
	off_plan_kc_desc_v o,
	plan_calendar_cd_v c,
	quarter_d_v q
WHERE k.keycomp_desc_pk=o.keycomp_desc_pk
AND	c.plan_calendar_pk = o.plan_calendar_pk
AND	q.qtr_pk=o.qtr_pk
AND   plan_date=(
	SELECT MAX(plan_date)
	FROM plan_calendar_cd_v p,
		off_plan_kc_desc_v o
	WHERE (off_plan_publish_flag='YES'
	OR spcr_publish_flag='YES')
	AND p.plan_calendar_pk=o.plan_calendar_pk)
AND   k.kcd_kc_type IN ('STORAGE_HD') 
GROUP BY k.keycomp_desc,
	q.qtr_fiscal_year_qtr;

INSERT INTO temp_table_ML
SELECT k.keycomp_desc kc_desc,
	q.qtr_fiscal_year_qtr fisc_qtr,
	sum(o.kc_desc_cfg_plan_qty) kc_config,
	0 kc_options,
	0 kc_flex
FROM	keycomp_desc_cd_v k,
	off_plan_plat_desc_drv_v o,
	plan_calendar_cd_v c,
	quarter_d_v q
WHERE k.keycomp_desc_pk=o.keycomp_desc_pk
AND	c.plan_calendar_pk = o.plan_calendar_pk
AND	q.qtr_pk=o.qtr_pk
AND   plan_date=(
	SELECT MAX(plan_date)
	FROM plan_calendar_cd_v p,
		off_plan_kc_desc_v o 
	WHERE (off_plan_publish_flag='YES'
	OR spcr_publish_flag='YES')
	AND p.plan_calendar_pk=o.plan_calendar_pk)
AND   k.kcd_kc_type IN ('STORAGE_HD') 
GROUP BY k.keycomp_desc,
	q.qtr_fiscal_year_qtr;
	
CREATE TABLE temp_table_ML2 AS
SELECT 	kc_desc,
	fisc_qtr,
	sum(kc_config) kc_config,
	sum(kc_options) kc_options,
	sum(kc_flex) kc_flex,
	0 total_kcp
FROM	temp_table_ML
GROUP BY kc_desc,
	fisc_qtr;
	
UPDATE temp_table_ML2
SET total_kcp=(kc_config+kc_options+kc_flex);

CREATE TABLE temp_table_ML3 AS
SELECT 	kc_desc,
	decode(fisc_qtr, '2002Q4',total_kcp,0) FY02Q4,
	decode(fisc_qtr, '2003Q1',total_kcp,0) FY03Q1,
	decode(fisc_qtr, '2003Q2',total_kcp,0) FY03Q2,
	decode(fisc_qtr, '2003Q3',total_kcp,0) FY03Q3,
	decode(fisc_qtr, '2003Q4',total_kcp,0) FY03Q4,
	decode(fisc_qtr, '2004Q1',total_kcp,0) FY04Q1
FROM temp_table_ML2
GROUP BY kc_desc,
	fisc_qtr,
	total_kcp
ORDER BY kc_desc,
	fisc_qtr,
	total_kcp;

PROMPT kc_desc,FY02Q4,FY03Q1,FY03Q2,FY03Q3,FY03Q4,FY04Q1,
SELECT 	kc_desc ||','||
	sum(FY02Q4) ||','||
	sum(FY03Q1) ||','||
	sum(FY03Q2) ||','||
	sum(FY03Q3) ||','||
	sum(FY03Q4) ||','||
	sum(FY04Q1) ||','
FROM temp_table_ML3
GROUP BY kc_desc
ORDER BY kc_desc;

COMMIT;
SPOOL OFF;

DROP TABLE temp_table_ML;
DROP TABLE temp_table_ML2;
DROP TABLE temp_table_ML3;

EXIT;

