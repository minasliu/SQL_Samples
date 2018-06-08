SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET VERIFY OFF;
/*****************************************************************************/
/*     File Name     : OverCons_Alert.sql                                    */
/*     Description   : Reports platforms at risk of overconsumption for AMP  */
/*     Input tables  : Sunpar_Kc_Desc_Summary, Sunpar_cr_Summary             */
/*     Output file   : /net/spmis.central/home/spmis/export/applix_charts/product/overConsData.csv*/
/*****************************************************************************/

SPOOL /net/spmis.central/home/spmis/export/applix_charts/product/overConsData.csv
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM') FROM dual;
PROMPT Current Qtr % Consumed sorted in descending order
PROMPT This report now excludes reman

CREATE TABLE plan_table_ML AS
SELECT	TRIM(kc_desc) kc_desc,
	TRIM(platform) platform,
	sum(plan_qty) kc_plan,
	changed_date
FROM 	Sunpar_Kc_Desc_Summary
WHERE 	(Kc_type IN ('STORAGE_HD') 
AND 	Kc_cat IN ('3.5" DISK', '2.5" DISK')
AND	rev_flag='B'
AND 	fiscal_qtr=
		(SELECT fiscal_year_qtr
		FROM date_cd_v
		WHERE TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY')))
GROUP BY platform,
	kc_desc,
	changed_date
ORDER BY platform,
	kc_desc,
	changed_date;

CREATE TABLE fill_table_ML AS
SELECT	TRIM(kc_desc) kc_desc,
	TRIM(platform_name) platform,
	sum(bklgcrdcurr) kc_blog,
	sum(ship_qty) kc_ships
FROM 	kc_qtr_data_v
WHERE	Kc_type IN ('STORAGE_HD') 
AND 	kc_cat IN ('3.5" DISK', '2.5" DISK')
AND	prod_no!=('R*')
AND	fiscal_qtr=
		(SELECT fiscal_year_qtr
		FROM date_cd_v
		WHERE TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
GROUP BY kc_desc,
	platform_name;

CREATE TABLE temp_table_ML AS
SELECT 	p.kc_desc kc_desc,
	p.platform platform,
	sum(p.kc_plan) kc_plan,
	sum(k.kc_blog+k.kc_ships) kc_fill,
	(sum(p.kc_plan)-sum(k.kc_blog+k.kc_ships)) remUnits,
	0 percent_fill
FROM	plan_table_ML p,
	fill_table_ML k
WHERE 	p.kc_desc=k.kc_desc
AND	p.platform=k.platform
AND 	p.changed_date=
		(SELECT MAX(changed_date)
		FROM plan_table_ML)
GROUP BY p.kc_desc,
	p.platform;	
	
UPDATE temp_table_ML
SET percent_fill=decode(kc_plan,0,0,(kc_fill/kc_plan)*100);

SET HEADING ON;
BREAK ON kc_desc

SELECT 	kc_desc,
	ROUND(percent_fill,0) || '%' || '  ' ||
	sum(remUnits) || '  ' ||
	platform
FROM 	temp_table_ML
WHERE 	percent_fill!=0
GROUP BY kc_desc,
	percent_fill,
	platform
ORDER BY kc_desc,
	percent_fill DESC,
	platform;

SPOOL OFF;
DROP TABLE temp_table_ML;
DROP TABLE plan_table_ML;
DROP TABLE fill_table_ML;

COMMIT;
exit;