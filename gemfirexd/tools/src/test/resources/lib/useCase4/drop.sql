ALTER TABLE APP.ORDERS
  DROP CONSTRAINT FKC3DF62E518A618B8;

ALTER TABLE APP.ORDERS
  DROP CONSTRAINT FKC3DF62E5D2E54D7A;

ALTER TABLE APP.ACCOUNT
  DROP CONSTRAINT FKE49F160D2BA34895;


-- ----------------------------------------------------------------------- 
-- QUOTE 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.QUOTE;

-- ----------------------------------------------------------------------- 
-- ORDERS 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.ORDERS;

-- ----------------------------------------------------------------------- 
-- HOLDING 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.HOLDING;

-- ----------------------------------------------------------------------- 
-- HIBERNATE_SEQUENCES 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.HIBERNATE_SEQUENCES;

-- ----------------------------------------------------------------------- 
-- ACCOUNTPROFILE 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.ACCOUNTPROFILE;

-- ----------------------------------------------------------------------- 
-- ACCOUNT 
-- ----------------------------------------------------------------------- 

DROP TABLE IF EXISTS APP.ACCOUNT;

-- ----------------------------------------------------------------------- 
-- PROCEDURE CHAOSFUNCTION 
-- ----------------------------------------------------------------------- 

DROP PROCEDURE CHAOSFUNCTION;

