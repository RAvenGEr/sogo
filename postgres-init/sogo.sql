CREATE DATABASE sogo;
\c sogo;
CREATE TABLE sogo_view (
  c_uid varchar(128) NOT NULL,
  c_name varchar(128) NOT NULL,
  c_password varchar(128) NOT NULL,
  c_cn varchar(128) DEFAULT NULL,
  mail varchar(128) NOT NULL,
  PRIMARY KEY (c_uid)
);
