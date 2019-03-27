SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Procedure structure for REVLOG_GENERATOR
-- ----------------------------
DROP PROCEDURE IF EXISTS `REVLOG_GENERATOR`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `REVLOG_GENERATOR`(in in_table_name varchar(50))
BEGIN


DECLARE done INT DEFAULT 0;
DECLARE tn CHAR(64);
DECLARE cn CHAR(64);
DECLARE ct CHAR(64);
DECLARE co CHAR(64);
DECLARE nu CHAR(5);
DECLARE cs CHAR(64);
DECLARE ck CHAR(64);


DECLARE table_cols CURSOR FOR SELECT
`COLUMNS`.TABLE_NAME,
`COLUMNS`.COLUMN_NAME,
`COLUMNS`.COLUMN_TYPE,
`COLUMNS`.COLLATION_NAME,
`COLUMNS`.`IS_NULLABLE`,
`COLUMNS`.`CHARACTER_SET_NAME`,
`COLUMNS`.`COLUMN_KEY`
FROM information_schema.`COLUMNS`
WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` LIKE in_table_name AND (COLUMN_NAME != 'rev_num' OR COLUMN_NAME != 'created' OR COLUMN_NAME != 'modified') AND COLUMN_KEY != 'PRI';


DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

SET @cr_t = CONCAT('CREATE TABLE if not exists ', in_table_name, '_revlog (
  `log_id` int(10) NOT NULL AUTO_INCREMENT,
  `id` char(36) DEFAULT NULL,
  `rev_num` int(20) DEFAULT NULL,
  `log` longtext,
  PRIMARY KEY (`log_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8' );

SET @trg = concat('CREATE TRIGGER ',in_table_name,'_up BEFORE UPDATE ON ',in_table_name,'
FOR EACH ROW
BEGIN
SET @val := CONCAT(');

OPEN table_cols;
  REPEAT
    FETCH table_cols INTO tn, cn, ct, co, nu,cs, ck;
    IF NOT (done) THEN
        set @con = concat(',"',cn,'"');
        set @com = concat('"');
     set @trg = concat(@trg, "if(new.", cn, " != ", "old.", cn, " ,","CONCAT('",@con,":",@com,"',old.",cn,",'",@com,"') ,'')
,");
    END IF;
  UNTIL done END REPEAT;
CLOSE table_cols;

SET @trg = trim(TRAILING ',' FROM @trg);
SET @trg = CONCAT(@trg,');');

SET @trg = CONCAT(@trg, '
IF(@val != "") THEN
set @val := TRIM(LEADING "," FROM @val);
set @val := CONCAT("{",@val,"}");
');

SET @trg = CONCAT(@trg, '
INSERT INTO ', in_table_name,'_revlog (  id, rev_num, log)
VALUES (old.id,old.rev_num
,@val);
SET old.rev_num = old.rev_num+1;
 ELSE
SET new.rev_num = if(new.rev_num != old.rev_num,old.rev_num,old.rev_num);
END IF;');

select @cr_t;
PREPARE stmt FROM @cr_t;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


set done=0;

select concat('DROP TRIGGER IF EXISTS ',in_table_name,'_up');
SELECT 'DELIMITER //';

SET @trg = left(@trg,length(@trg)-1);
SET @trg = CONCAT(@trg, '
END' );
select @trg;
/*
PREPARE stmt FROM @trg;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
*/
END;;
DELIMITER ;

